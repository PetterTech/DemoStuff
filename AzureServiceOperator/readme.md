# Azure Service Operator on AKS Automatic

This demo deploys an AKS Automatic cluster with Azure Service Operator (ASO) v2 configured using Workload Identity.

## Repository structure

```
AzureServiceOperator/
├── Deploy.ps1               # One-command bootstrap script
├── infrastructure/          # Bicep templates for Azure resources
│   ├── main.bicep           # Orchestrator — deploys AKS + identity
│   ├── aks.bicep            # AKS Automatic cluster
│   └── asoIdentity.bicep    # Managed identity + federated credential
├── kubernetes/
│   ├── aso-values.yaml      # Helm values for ASO install (with placeholders)
│   └── examples/            # Sample managed resources
│       └── storage-account.yaml
└── readme.md
```

## What gets deployed

**Bicep (infrastructure):**
- AKS Automatic cluster (system-assigned identity) with OIDC issuer and workload identity enabled
- AKS RBAC Cluster Admin role assignment for the deploying user
- User-assigned managed identity for the ASO operator
- Federated identity credential linking AKS to the ASO operator service account
- Contributor role assignment on the resource group

**Kubernetes (Helm + YAML manifests):**
- cert-manager v1.17.2 (required by ASO for webhook TLS certificates)
- Azure Service Operator v2 (via Helm), configured with Azure Workload Identity

## Prerequisites

- Azure PowerShell (`Az.Accounts`, `Az.Resources`, `Az.Aks` modules) with an active login (`Connect-AzAccount`)
  - The deploy script will auto-install missing modules into the CurrentUser scope
- `kubectl` and `kubelogin`
- Helm 3

## Quick start

`Deploy.ps1` automates all the steps below into a single command:

```powershell
cd AzureServiceOperator
.\Deploy.ps1 -StorageAccountName "mystgaso01"
```

The script deploys the following end to end:

1. **Azure infrastructure** (via Bicep) — AKS Automatic cluster, managed identity, and federated credential
2. **cert-manager** — required by ASO for webhook TLS certificates
3. **Azure Service Operator** (via Helm) — installed into the `azureserviceoperator-system` namespace, configured with Workload Identity

When the script finishes, ASO is fully operational and ready to manage Azure resources. The `-StorageAccountName` value is pre-filled into the example manifest so you can immediately try it out:

```powershell
kubectl apply -f .generated/examples/storage-account.yaml
kubectl get storageaccount -w
```

This creates a real Azure Storage Account (Standard LRS, Sweden Central) managed by ASO. Once `READY=True`, the account exists in Azure. Delete the manifest to have ASO remove it automatically.

---

**Flags:**

Use `-SkipInfrastructure` to skip Bicep deployment when re-running against an existing cluster.

Use `-Cleanup` to tear down everything (resource group + `.generated/` folder).

Optional overrides: `-ResourceGroupName` (default: `rg-aso`), `-Location` (default: `swedencentral`).

The script writes generated YAML (with placeholders replaced) to `.generated/` so the originals stay reusable as templates.

---

## Manual steps (reference)

## 1. Deploy infrastructure

```powershell
$rgName = "rg-aso"

New-AzResourceGroup -Name $rgName -Location swedencentral -Force

$principalId = (Get-AzADUser -SignedIn).Id

New-AzResourceGroupDeployment `
  -Name 'main' `
  -ResourceGroupName $rgName `
  -TemplateFile infrastructure/main.bicep `
  -clusterAdminPrincipalId $principalId
```

Save the outputs — you'll need them for placeholder replacement in the YAML files:

```powershell
$deployment = Get-AzResourceGroupDeployment -ResourceGroupName $rgName -Name 'main'

$clusterName = $deployment.Outputs['clusterName'].Value
$clientId = $deployment.Outputs['asoIdentityClientId'].Value
$context = Get-AzContext
$subscriptionId = $context.Subscription.Id
$tenantId = $context.Tenant.Id
```

## 2. Replace placeholders in YAML files

The Kubernetes manifests use angle-bracket placeholders for environment-specific values. Replace them before applying:

| Placeholder | Value | Used in |
|---|---|---|
| `<ASO_IDENTITY_CLIENT_ID>` | `$clientId` | `aso-values.yaml` |
| `<SUBSCRIPTION_ID>` | `$subscriptionId` | `aso-values.yaml`, `storage-account.yaml` |
| `<TENANT_ID>` | `$tenantId` | `aso-values.yaml` |
| `<RESOURCE_GROUP_NAME>` | `$rgName` | `storage-account.yaml` |
| `<STORAGE_ACCOUNT_NAME>` | `$storageAccountName` | `storage-account.yaml` |

```powershell
$storageAccountName = 'youruniquestoragename'  # Replace with a globally unique name (3-24 chars, lowercase + numbers)

$files = Get-ChildItem -Path kubernetes -Recurse -Filter *.yaml

foreach ($file in $files) {
    (Get-Content $file.FullName -Raw) `
        -replace '<ASO_IDENTITY_CLIENT_ID>', $clientId `
        -replace '<SUBSCRIPTION_ID>', $subscriptionId `
        -replace '<TENANT_ID>', $tenantId `
        -replace '<RESOURCE_GROUP_NAME>', $rgName `
        -replace '<STORAGE_ACCOUNT_NAME>', $storageAccountName |
        Set-Content $file.FullName
}
```

## 3. Connect to the cluster

```powershell
Import-AzAksCredential -ResourceGroupName $rgName -Name $clusterName -Force
kubelogin convert-kubeconfig -l azurecli
```

> **Note:** AKS Automatic uses Entra ID authentication. The `kubelogin convert-kubeconfig -l azurecli` command configures kubectl to reuse your existing `az login` session, which avoids Conditional Access issues with interactive browser sign-in.

## 4. Install cert-manager

cert-manager is a hard prerequisite for ASO v2 — ASO uses it for webhook TLS certificates.

```powershell
# Remove the ValidatingAdmissionPolicy binding that may block webhook installs on AKS Automatic
kubectl delete validatingadmissionpolicybinding aks-managed-block-nodes-proxy-rbac-binding --ignore-not-found

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml

kubectl wait deployment cert-manager cert-manager-cainjector cert-manager-webhook `
  --for=condition=Available `
  --namespace cert-manager `
  --timeout=300s
```

> **Note:** AKS will automatically recreate the `ValidatingAdmissionPolicyBinding` after a reconciliation cycle.

## 5. Install Azure Service Operator

ASO is installed as a single Helm chart. The Workload Identity configuration is passed via the values file.

```powershell
helm repo add asohelmchart https://raw.githubusercontent.com/Azure/azure-service-operator/main/v2/charts
helm repo update

helm upgrade aso asohelmchart/azure-service-operator `
  --install `
  --namespace azureserviceoperator-system `
  --create-namespace `
  --values kubernetes/aso-values.yaml `
  --wait
```

Wait for ASO pods to be ready:

```powershell
kubectl get pods -n azureserviceoperator-system -w
```

## 6. Verify

```powershell
# ASO manager pod should be Running
kubectl get pods -n azureserviceoperator-system

# Check operator logs for any auth errors
kubectl logs -n azureserviceoperator-system -l control-plane=controller-manager --tail=20
```

## 7. Try it out — create a Storage Account

```powershell
kubectl apply -f kubernetes/examples/storage-account.yaml
```

Watch it provision:

```powershell
kubectl get storageaccount -w
```

Once `READY` is `True`, the storage account exists in Azure. You can verify with:

```powershell
Get-AzStorageAccount -ResourceGroupName $rgName -Name $storageAccountName | Select-Object StorageAccountName, ProvisioningState
```

> **Note:** The ASO identity has Contributor on `rg-aso` only, so all resources must be created within that resource group.

Delete the managed resource when done:

```powershell
kubectl delete -f kubernetes/examples/storage-account.yaml
```

ASO will automatically delete the storage account from Azure.

## Cleanup

Use the `-Cleanup` flag to tear everything down — removes the Azure resource group and the local `.generated/` folder:

```powershell
.\Deploy.ps1 -Cleanup
```

Or manually:

```powershell
Remove-AzResourceGroup -Name $rgName -Force -AsJob
```

## Next steps

With ASO configured, you can start creating Azure resources using Kubernetes manifests. ASO supports a wide range of Azure services — explore the full list at [azure.github.io/azure-service-operator](https://azure.github.io/azure-service-operator/).

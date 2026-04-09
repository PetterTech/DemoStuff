# Crossplane on AKS Automatic

This demo deploys an AKS Automatic cluster with Crossplane and the Azure provider configured using Workload Identity.

## Repository structure

```
Crossplane/
├── Deploy.ps1               # One-command bootstrap script
├── infrastructure/          # Bicep templates for Azure resources
│   ├── main.bicep           # Orchestrator — deploys AKS + identity
│   ├── aks.bicep            # AKS Automatic cluster
│   └── crossplaneIdentity.bicep  # Managed identity + federated credential
├── kubernetes/
│   ├── crossplane/          # Core Crossplane configuration
│   │   ├── service-account.yaml
│   │   ├── deployment-runtime-config.yaml
│   │   └── crossplane-values.yaml  # Helm values for Crossplane install
│   ├── providers/           # Azure provider installation & config
│   │   ├── provider-family-azure.yaml
│   │   ├── provider-azure-storage.yaml
│   │   └── provider-config.yaml
│   ├── platform/            # Future XRDs, Compositions & Claims
│   │   └── README.md
│   └── examples/            # Sample managed resources
│       └── storage-account.yaml
└── readme.md
```

## What gets deployed

**Bicep (infrastructure):**
- AKS Automatic cluster (system-assigned identity) with OIDC issuer and workload identity enabled
- AKS RBAC Cluster Admin role assignment for the deploying user
- User-assigned managed identity for the Crossplane Azure provider
- Federated identity credential linking AKS to the Crossplane service account
- Contributor role assignment on the resource group

**Kubernetes (YAML manifests):**
- Crossplane (via Helm)
- Upbound Azure provider family (`provider-family-azure`)
- ProviderConfig using Azure Workload Identity

## Prerequisites

- Azure PowerShell (`Az.Accounts`, `Az.Resources`, `Az.Aks` modules) with an active login (`Connect-AzAccount`)
  - The deploy script will auto-install missing modules into the CurrentUser scope
- `kubectl` and `kubelogin`
- Helm 3

## Quick start

`Deploy.ps1` automates all the steps below into a single command:

```powershell
cd Crossplane
.\Deploy.ps1 -StorageAccountName "mystgcrossplane01"
```

Use `-SkipInfrastructure` to skip Bicep deployment when re-running against an existing cluster.

Use `-Cleanup` to tear down everything (resource group + `.generated/` folder).

Optional overrides: `-ResourceGroupName` (default: `rg-crossplane`), `-Location` (default: `swedencentral`).

The script writes generated YAML (with placeholders replaced) to `.generated/` so the originals stay reusable as templates.

---

## Manual steps (reference)

## 1. Deploy infrastructure

```powershell
$rgName = "rg-crossplane"

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
$clientId = $deployment.Outputs['crossplaneIdentityClientId'].Value
$context = Get-AzContext
$subscriptionId = $context.Subscription.Id
$tenantId = $context.Tenant.Id
```

## 2. Replace placeholders in YAML files

The Kubernetes manifests use angle-bracket placeholders for environment-specific values. Replace them before applying:

| Placeholder | Value | Used in |
|---|---|---|
| `<CROSSPLANE_IDENTITY_CLIENT_ID>` | `$clientId` | `service-account.yaml`, `provider-config.yaml` |
| `<SUBSCRIPTION_ID>` | `$subscriptionId` | `provider-config.yaml` |
| `<TENANT_ID>` | `$tenantId` | `provider-config.yaml` |
| `<RESOURCE_GROUP_NAME>` | `$rgName` | `storage-account.yaml` |
| `<STORAGE_ACCOUNT_NAME>` | `$storageAccountName` | `storage-account.yaml` |

```powershell
$storageAccountName = 'youruniquestoragename'  # Replace with a globally unique name (3-24 chars, lowercase + numbers)

$files = Get-ChildItem -Path kubernetes -Recurse -Filter *.yaml

foreach ($file in $files) {
    (Get-Content $file.FullName -Raw) `
        -replace '<CROSSPLANE_IDENTITY_CLIENT_ID>', $clientId `
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

## 4. Install Crossplane

AKS Automatic has a built-in `ValidatingAdmissionPolicy` that conflicts with Crossplane's aggregated ClusterRoles (which have null rules). Remove the policy binding before installing:

```powershell
kubectl delete validatingadmissionpolicybinding aks-managed-block-nodes-proxy-rbac-binding
```

> **Note:** AKS will automatically recreate this binding after a reconciliation cycle, so this is a temporary workaround.

```powershell
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm upgrade crossplane crossplane-stable/crossplane `
  --install `
  --namespace crossplane-system `
  --create-namespace `
  --values kubernetes/crossplane/crossplane-values.yaml
```

Wait for Crossplane pods to be ready:

```powershell
kubectl get pods -n crossplane-system -w
```

## 5. Configure the Azure provider

### 5.1 Create the ServiceAccount and DeploymentRuntimeConfig

The federated credential created by Bicep expects a service account named `provider-azure` in the `crossplane-system` namespace:

```powershell
kubectl apply -f kubernetes/crossplane/service-account.yaml
kubectl apply -f kubernetes/crossplane/deployment-runtime-config.yaml
```

### 5.2 Install the Azure provider

```powershell
kubectl apply -f kubernetes/providers/provider-family-azure.yaml
```

Wait for the provider to become healthy:

```powershell
kubectl get providers.pkg.crossplane.io -w
```

### 5.3 Create a ProviderConfig

```powershell
kubectl apply -f kubernetes/providers/provider-config.yaml
```

## 6. Verify

```powershell
# Provider should show INSTALLED=True and HEALTHY=True
kubectl get providers.pkg.crossplane.io

# ProviderConfig should exist
kubectl get providerconfigs.azure.upbound.io
```

## 7. Try it out — create a Storage Account

Install the Azure Storage provider:

```powershell
kubectl apply -f kubernetes/providers/provider-azure-storage.yaml
```

Wait for it to become healthy:

```powershell
kubectl get providers.pkg.crossplane.io -w
```

Create a storage account to verify everything works end to end:

```powershell
kubectl apply -f kubernetes/examples/storage-account.yaml
```

Watch it provision:

```powershell
kubectl get account.storage.azure.upbound.io -w
```

Once `READY` is `True` and `SYNCED` is `True`, the storage account exists in Azure. You can verify with:

```powershell
Get-AzStorageAccount -ResourceGroupName $rgName -Name $storageAccountName | Select-Object StorageAccountName, ProvisioningState
```

> **Note:** The Crossplane identity has Contributor on `rg-crossplane` only, so all resources must be created within that resource group.

Delete the managed resource when done:

```powershell
kubectl delete -f kubernetes/examples/storage-account.yaml
```

Crossplane will automatically delete the storage account from Azure.

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

With the Azure provider configured, you can start creating Azure resources using Crossplane. Define Managed Resources or build Compositions and Claims to create higher-level abstractions (e.g. landing zone provisioning via XRDs).

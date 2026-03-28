# Radius on AKS Automatic

This demo deploys an AKS Automatic cluster with Radius and the Azure cloud provider configured using Workload Identity.

## Repository structure

```
Radius/
├── Deploy.ps1               # One-command bootstrap script
├── infrastructure/          # Bicep templates for Azure resources
│   ├── main.bicep           # Orchestrator — deploys AKS + identity
│   ├── aks.bicep            # AKS Automatic cluster
│   └── radiusIdentity.bicep # Managed identity + federated credential for Radius UCP
├── kubernetes/
│   ├── radius/              # Helm values for Radius installation
│   │   └── radius-values.yaml
│   ├── recipes/             # Future home for Radius environment recipes
│   │   └── README.md
│   └── examples/            # Sample Radius applications
│       └── app.bicep
└── readme.md
```

## What gets deployed

**Bicep (infrastructure):**
- AKS Automatic cluster (system-assigned identity) with OIDC issuer and workload identity enabled
- AKS RBAC Cluster Admin role assignment for the deploying user
- User-assigned managed identity for the Radius UCP component
- Federated identity credential linking AKS to the Radius UCP service account (`radius-system/ucp`)
- Contributor role assignment on the resource group

**Kubernetes (via rad CLI):**
- Radius (via `rad install kubernetes`, Azure Workload Identity enabled)
- Azure cloud provider credential (`rad credential register azure wi`)
- Radius environment `dev` scoped to the resource group (`rad env create` + `rad env update`)

## Prerequisites

- Azure PowerShell (`Az.Accounts`, `Az.Resources`, `Az.Aks` modules) with an active login (`Connect-AzAccount`)
  - The deploy script will auto-install missing modules into the CurrentUser scope
- `kubectl` and `kubelogin`
- `rad` CLI — [installation guide](https://docs.radapp.io/installation/)

## Quick start

`Deploy.ps1` automates all the steps below into a single command:

```powershell
cd Radius
.\Deploy.ps1
```

Use `-SkipInfrastructure` to skip Bicep deployment when re-running against an existing cluster.

The script writes generated files (with placeholders replaced) to `.generated/` so the originals stay reusable as templates.

---

## Manual steps (reference)

## 1. Deploy infrastructure

```powershell
$rgName = "rg-radius"

New-AzResourceGroup -Name $rgName -Location swedencentral -Force

$principalId = (Get-AzADUser -SignedIn).Id

New-AzResourceGroupDeployment `
  -Name 'main' `
  -ResourceGroupName $rgName `
  -TemplateFile infrastructure/main.bicep `
  -clusterAdminPrincipalId $principalId
```

Save the outputs — you'll need them for subsequent steps:

```powershell
$deployment = Get-AzResourceGroupDeployment -ResourceGroupName $rgName -Name 'main'

$clusterName = $deployment.Outputs['clusterName'].Value
$clientId    = $deployment.Outputs['radiusIdentityClientId'].Value
$context     = Get-AzContext
$subscriptionId = $context.Subscription.Id
$tenantId       = $context.Tenant.Id
```

## 2. Replace placeholders in Helm values

The Helm values file uses an angle-bracket placeholder for the managed identity client ID:

| Placeholder | Value | Used in |
|---|---|---|
| `<RADIUS_IDENTITY_CLIENT_ID>` | `$clientId` | `radius-values.yaml` |

```powershell
(Get-Content kubernetes/radius/radius-values.yaml -Raw) `
    -replace '<RADIUS_IDENTITY_CLIENT_ID>', $clientId |
    Set-Content kubernetes/radius/radius-values.yaml
```

## 3. Connect to the cluster

```powershell
Import-AzAksCredential -ResourceGroupName $rgName -Name $clusterName -Force
kubelogin convert-kubeconfig -l azurecli
```

> **Note:** AKS Automatic uses Entra ID authentication. The `kubelogin convert-kubeconfig -l azurecli` command configures kubectl to reuse your existing `az login` session, which avoids Conditional Access issues with interactive browser sign-in.

## 4. Install Radius

```powershell
rad install kubernetes --values kubernetes/radius/radius-values.yaml
```

The `global.azureWorkloadIdentity.enabled=true` value in `radius-values.yaml` tells Radius to annotate the `ucp` service account with the managed identity client ID, enabling the UCP pod to exchange AKS OIDC tokens for Azure credentials.

Wait for Radius pods to be ready:

```powershell
kubectl get pods -n radius-system -w
```

## 5. Register the Azure credential

```powershell
rad credential register azure wi --client-id $clientId --tenant-id $tenantId
```

Radius stores this in the cluster and uses it when provisioning Azure resources from recipes.

## 6. Create a Radius environment

```powershell
rad env create dev --namespace default
rad env update dev `
  --azure-subscription-id $subscriptionId `
  --azure-resource-group $rgName
```

The environment scopes Azure resource provisioning to a specific subscription and resource group.

## 7. Verify

```powershell
# Credential should show as registered
rad credential list

# Environment should exist
rad env list
```

## 8. Try it out — deploy the example application

```powershell
rad deploy kubernetes/examples/app.bicep --environment dev
```

This deploys a simple nginx container managed by Radius. Inspect the application graph:

```powershell
rad app graph demo
```

List running applications:

```powershell
rad app list
```

Delete the application when done:

```powershell
rad app delete demo
```

## Cleanup

```powershell
.\Deploy.ps1 -Cleanup
```

Or manually:

```powershell
Remove-AzResourceGroup -Name $rgName -Force -AsJob
```

## Next steps

With Radius installed and an Azure environment configured, you can:

- **Add recipes** — define reusable infrastructure templates that map portable resource types (e.g. `Applications.Datastores/redisCaches`) to Azure resources. See `kubernetes/recipes/` for a placeholder.
- **Deploy real applications** — extend `app.bicep` to include connections to Azure resources provisioned via recipes.
- **Explore the Radius dashboard** — `rad dashboard` opens a local web UI showing all applications and their connections.

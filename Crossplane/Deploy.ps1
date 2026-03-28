<#
.SYNOPSIS
    Deploys the Crossplane-on-AKS-Automatic demo end to end.

.DESCRIPTION
    Automates: resource group creation, Bicep deployment, AKS credential setup,
    Crossplane installation via Helm, placeholder replacement in YAML manifests,
    and sequential application of Kubernetes resources.

    Uses Azure PowerShell cmdlets (Az module) for all Azure operations — these
    throw terminating errors on failure, so the script halts immediately if
    anything goes wrong. External tools (kubectl, helm, kubelogin) are checked
    via exit code after each call.

    Original YAML files are left untouched — generated copies with real values
    are written to .generated/ and applied from there.

.PARAMETER ResourceGroupName
    Name of the Azure resource group. Default: rg-crossplane.

.PARAMETER Location
    Azure region for all resources. Default: swedencentral.

.PARAMETER StorageAccountName
    Globally unique name for the example storage account (3-24 chars, lowercase + numbers).

.PARAMETER SkipInfrastructure
    Skip Bicep deployment and resource group creation. Useful when re-running
    only the Kubernetes configuration steps against an existing cluster.

.PARAMETER Cleanup
    Tears down everything: deletes the Azure resource group (and all resources
    within it) and removes the local .generated/ folder.

.LINK
    https://www.crossplane.io/

.EXAMPLE
    .\Deploy.ps1
    .\Deploy.ps1 -StorageAccountName "mystgcrossplane01"
    .\Deploy.ps1 -SkipInfrastructure
    .\Deploy.ps1 -Cleanup
#>

[CmdletBinding()]
param(
    [string]$ResourceGroupName = 'rg-crossplane',
    [string]$Location = 'swedencentral',
    [string]$StorageAccountName = 'youruniquestoragename',
    [switch]$SkipInfrastructure,
    [switch]$Cleanup
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Script related variables
$ScriptRoot = $PSScriptRoot
$GeneratedDir = Join-Path $ScriptRoot '.generated'

# Module related variables
$RequiredModules = @('Az.Accounts', 'Az.Resources', 'Az.Aks')

########################################################################
#                     DO NOT EDIT BELOW THIS LINE                      #
########################################################################

$ElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()

########################################################################
#                          Preparations                                #
########################################################################

#region Preparations

Write-Verbose 'Ensuring required Az modules are installed.'

$Progress = 0
foreach ($Module in $RequiredModules) {
    Write-Progress -Activity 'Checking Az modules' -Status $Module -PercentComplete ($Progress / $RequiredModules.Count * 100) -ErrorAction SilentlyContinue
    if (-not (Get-Module -Name $Module -ListAvailable)) {
        Write-Verbose "Installing missing module '$Module'..."
        Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
        Write-Verbose "Module '$Module' installed successfully."
    }
    Import-Module $Module -ErrorAction Stop
    Write-Verbose "Module '$Module' loaded."
    $Progress++
}
Write-Progress -Activity 'Checking Az modules' -Completed -ErrorAction SilentlyContinue

#endregion Preparations

########################################################################
#                            Cleanup                                   #
########################################################################

#region Cleanup

if ($Cleanup) {
    Write-Verbose 'Cleanup mode activated.'

    # Resolve the resource group name from the saved deployment context
    $ContextFile = Join-Path $GeneratedDir 'deployment-context.json'
    if (Test-Path $ContextFile) {
        $SavedContext = Get-Content $ContextFile -Raw | ConvertFrom-Json
        $ResourceGroupName = $SavedContext.ResourceGroupName
        Write-Verbose "Loaded resource group name '$ResourceGroupName' from deployment context."
    }
    else {
        Write-Warning "No deployment context found in .generated/ — using parameter value '$ResourceGroupName'. Verify this is the correct resource group before continuing."
    }

    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if ($ResourceGroup) {
        Write-Verbose "Deleting resource group '$ResourceGroupName'..."
        Remove-AzResourceGroup -Name $ResourceGroupName -Force
        Write-Verbose "Resource group '$ResourceGroupName' deleted."
    }
    else {
        Write-Verbose "Resource group '$ResourceGroupName' not found — nothing to delete."
    }

    if (Test-Path $GeneratedDir) {
        Write-Verbose 'Removing .generated/ folder...'
        Remove-Item $GeneratedDir -Recurse -Force
        Write-Verbose 'Removed .generated/ folder.'
    }

    Write-Verbose "Cleanup complete. Elapsed time: $($ElapsedTime.Elapsed.ToString())."
    return
}

#endregion Cleanup

function Assert-ExitCode {
    <#
    .SYNOPSIS
        Throws if the last external command returned a non-zero exit code.
    .PARAMETER Message
        Error message to include in the thrown exception.
    .EXAMPLE
        Assert-ExitCode 'kubectl apply failed.'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = 'Error message to throw on failure.')]
        [string]$Message
    )

    if ($LASTEXITCODE -ne 0) {
        throw "$Message (exit code: $LASTEXITCODE)"
    }
}

########################################################################
#               Part 1 - Deploying infrastructure                     #
########################################################################

#region Part 1 - Deploying infrastructure

Write-Progress -Id 0 -Activity 'Crossplane deployment' -Status 'Part 1 of 6 — Deploying infrastructure' -PercentComplete 0 -ErrorAction SilentlyContinue

if (-not $SkipInfrastructure) {
    Write-Verbose 'Deploying infrastructure...'

    Write-Progress -Id 1 -ParentId 0 -Activity 'Infrastructure' -Status 'Creating resource group...' -PercentComplete 0 -ErrorAction SilentlyContinue
    try {
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force | Out-Null
        Write-Verbose "Resource group '$ResourceGroupName' ready."
    }
    catch {
        Write-Verbose "Failed to create resource group '$ResourceGroupName': $($_.Exception.Message)"
        throw
    }

    # Save deployment context so cleanup can find the correct resource group
    if (-not (Test-Path $GeneratedDir)) { New-Item -Path $GeneratedDir -ItemType Directory -Force | Out-Null }
    @{ ResourceGroupName = $ResourceGroupName } | ConvertTo-Json | Set-Content (Join-Path $GeneratedDir 'deployment-context.json')
    Write-Verbose 'Saved deployment context to .generated/deployment-context.json.'

    try {
        $Context = Get-AzContext -ErrorAction Stop
        if (-not $Context) { throw 'No Azure context found. Run Connect-AzAccount first.' }
    }
    catch {
        Write-Verbose "Failed to get Azure context: $($_.Exception.Message)"
        throw
    }

    try {
        $PrincipalId = (Get-AzADUser -SignedIn -ErrorAction Stop).Id
        if (-not $PrincipalId) { throw 'Could not determine signed-in user principal ID.' }
        Write-Verbose "Signed-in user principal ID: $PrincipalId"
    }
    catch {
        Write-Verbose "Failed to get signed-in user principal ID: $($_.Exception.Message)"
        throw
    }

    Write-Verbose 'Starting Bicep deployment...'
    Write-Progress -Id 1 -ParentId 0 -Activity 'Infrastructure' -Status 'Bicep deployment in progress — this may take a while...' -PercentComplete 25 -ErrorAction SilentlyContinue
    try {
        $DeploymentJob = New-AzResourceGroupDeployment `
            -Name 'main' `
            -ResourceGroupName $ResourceGroupName `
            -TemplateFile "$ScriptRoot/infrastructure/main.bicep" `
            -clusterAdminPrincipalId $PrincipalId `
            -AsJob

        while ($DeploymentJob.State -eq 'Running') {
            Start-Sleep -Seconds 5
            $MinutesElapsed = [math]::Round(((Get-Date) - $DeploymentJob.PSBeginTime).TotalMinutes, 1)
            Write-Progress -Id 1 -ParentId 0 -Activity 'Infrastructure' -Status "Bicep deployment in progress — $MinutesElapsed min elapsed" -PercentComplete 50 -ErrorAction SilentlyContinue
        }

        $DeploymentJob | Receive-Job -Wait -AutoRemoveJob | Out-Null
        Write-Verbose 'Bicep deployment complete.'
    }
    catch {
        Write-Verbose "Bicep deployment failed: $($_.Exception.Message)"
        throw
    }
    Write-Progress -Id 1 -ParentId 0 -Activity 'Infrastructure' -Completed -ErrorAction SilentlyContinue
}
else {
    Write-Verbose 'Skipping infrastructure deployment (SkipInfrastructure flag set).'
}

#endregion Part 1 - Deploying infrastructure

########################################################################
#             Part 2 - Capturing deployment outputs                    #
########################################################################

#region Part 2 - Capturing deployment outputs

Write-Progress -Id 0 -Activity 'Crossplane deployment' -Status 'Part 2 of 6 — Capturing deployment outputs' -PercentComplete 17 -ErrorAction SilentlyContinue
Write-Verbose 'Capturing deployment outputs...'

try {
    $Deployment = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name 'main' -ErrorAction Stop
    Write-Verbose 'Retrieved deployment outputs.'
}
catch {
    Write-Verbose "Failed to get deployment '$ResourceGroupName/main': $($_.Exception.Message)"
    throw
}

$ClusterName    = $Deployment.Outputs['clusterName'].Value
$ClientId       = $Deployment.Outputs['crossplaneIdentityClientId'].Value

try {
    $Context        = Get-AzContext -ErrorAction Stop
    $SubscriptionId = $Context.Subscription.Id
    $TenantId       = $Context.Tenant.Id
}
catch {
    Write-Verbose "Failed to get Azure context: $($_.Exception.Message)"
    throw
}

Write-Verbose "Cluster:        $ClusterName"
Write-Verbose "Client ID:      $ClientId"
Write-Verbose "Subscription:   $SubscriptionId"
Write-Verbose "Tenant:         $TenantId"

#endregion Part 2 - Capturing deployment outputs

########################################################################
#             Part 3 - Generating YAML manifests                       #
########################################################################

#region Part 3 - Generating YAML manifests

Write-Progress -Id 0 -Activity 'Crossplane deployment' -Status 'Part 3 of 6 — Generating YAML manifests' -PercentComplete 33 -ErrorAction SilentlyContinue
Write-Verbose 'Generating YAML manifests...'

if (Test-Path $GeneratedDir) { Remove-Item $GeneratedDir -Recurse -Force }

Copy-Item -Path (Join-Path $ScriptRoot 'kubernetes') -Destination $GeneratedDir -Recurse

$YamlFiles = Get-ChildItem -Path $GeneratedDir -Recurse -Filter *.yaml

$Progress = 0
foreach ($File in $YamlFiles) {
    Write-Progress -Id 1 -ParentId 0 -Activity 'Processing YAML manifests' -Status $File.Name -PercentComplete ($Progress / $YamlFiles.Count * 100) -ErrorAction SilentlyContinue
    (Get-Content $File.FullName -Raw) `
        -replace '<CROSSPLANE_IDENTITY_CLIENT_ID>', $ClientId `
        -replace '<SUBSCRIPTION_ID>', $SubscriptionId `
        -replace '<TENANT_ID>', $TenantId `
        -replace '<RESOURCE_GROUP_NAME>', $ResourceGroupName `
        -replace '<STORAGE_ACCOUNT_NAME>', $StorageAccountName |
        Set-Content $File.FullName
    $Progress++
}
Write-Progress -Id 1 -ParentId 0 -Activity 'Processing YAML manifests' -Completed -ErrorAction SilentlyContinue

Write-Verbose "Generated manifests in $GeneratedDir"

#endregion Part 3 - Generating YAML manifests

########################################################################
#              Part 4 - Connecting to cluster                          #
########################################################################

#region Part 4 - Connecting to cluster

Write-Progress -Id 0 -Activity 'Crossplane deployment' -Status 'Part 4 of 6 — Connecting to cluster' -PercentComplete 50 -ErrorAction SilentlyContinue
Write-Verbose 'Connecting to cluster...'

try {
    Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Force -ErrorAction Stop
    Write-Verbose 'AKS credentials imported.'
}
catch {
    Write-Verbose "Failed to import AKS credentials for '$ClusterName': $($_.Exception.Message)"
    throw
}

try {
    kubelogin convert-kubeconfig -l azurecli
    Assert-ExitCode 'kubelogin convert-kubeconfig failed.'
    Write-Verbose 'kubectl configured.'
}
catch {
    Write-Verbose "kubelogin failed: $($_.Exception.Message)"
    throw
}

#endregion Part 4 - Connecting to cluster

########################################################################
#              Part 5 - Installing Crossplane                          #
########################################################################

#region Part 5 - Installing Crossplane

Write-Progress -Id 0 -Activity 'Crossplane deployment' -Status 'Part 5 of 6 — Installing Crossplane' -PercentComplete 67 -ErrorAction SilentlyContinue
Write-Verbose 'Installing Crossplane...'

# Remove the ValidatingAdmissionPolicy binding that conflicts with Crossplane
kubectl delete validatingadmissionpolicybinding aks-managed-block-nodes-proxy-rbac-binding --ignore-not-found 2>$null
# Intentionally not checking exit code — binding may already be absent

try {
    Write-Verbose 'Adding Crossplane Helm repo...'
    helm repo add crossplane-stable https://charts.crossplane.io/stable --force-update | Out-Null
    Assert-ExitCode 'helm repo add failed.'

    helm repo update | Out-Null
    Assert-ExitCode 'helm repo update failed.'
    Write-Verbose 'Helm repo configured.'
}
catch {
    Write-Verbose "Failed to configure Helm repo: $($_.Exception.Message)"
    throw
}

try {
    Write-Verbose 'Installing Crossplane via Helm...'
    Write-Progress -Id 1 -ParentId 0 -Activity 'Helm install' -Status 'Installing Crossplane chart — waiting for pods...' -PercentComplete 50 -ErrorAction SilentlyContinue
    helm upgrade crossplane crossplane-stable/crossplane `
        --install `
        --namespace crossplane-system `
        --create-namespace `
        --values "$GeneratedDir/crossplane/crossplane-values.yaml" `
        --wait
    Assert-ExitCode 'helm upgrade/install crossplane failed.'
    Write-Progress -Id 1 -ParentId 0 -Activity 'Helm install' -Completed -ErrorAction SilentlyContinue
    Write-Verbose 'Crossplane installed and ready.'
}
catch {
    Write-Verbose "Helm install/upgrade failed: $($_.Exception.Message)"
    throw
}

#endregion Part 5 - Installing Crossplane

########################################################################
#            Part 6 - Applying Kubernetes manifests                    #
########################################################################

#region Part 6 - Applying Kubernetes manifests

Write-Progress -Id 0 -Activity 'Crossplane deployment' -Status 'Part 6 of 6 — Applying Kubernetes manifests' -PercentComplete 83 -ErrorAction SilentlyContinue

try {
    Write-Verbose 'Applying ServiceAccount and DeploymentRuntimeConfig...'
    kubectl apply -f "$GeneratedDir/crossplane/service-account.yaml"
    Assert-ExitCode 'Failed to apply service-account.yaml.'

    kubectl apply -f "$GeneratedDir/crossplane/deployment-runtime-config.yaml"
    Assert-ExitCode 'Failed to apply deployment-runtime-config.yaml.'
    Write-Verbose 'ServiceAccount and DeploymentRuntimeConfig applied.'
}
catch {
    Write-Verbose "Failed to apply Crossplane base manifests: $($_.Exception.Message)"
    throw
}

try {
    Write-Verbose 'Applying provider-family-azure...'
    kubectl apply -f "$GeneratedDir/providers/provider-family-azure.yaml"
    Assert-ExitCode 'Failed to apply provider-family-azure.yaml.'

    Write-Verbose 'Waiting for provider-family-azure to become healthy...'
    Write-Progress -Id 1 -ParentId 0 -Activity 'Providers' -Status 'Waiting for provider-family-azure to become healthy...' -PercentComplete 33 -ErrorAction SilentlyContinue
    kubectl wait --for=condition=Healthy providers.pkg.crossplane.io/provider-family-azure --timeout=300s
    Assert-ExitCode 'provider-family-azure did not become healthy within timeout.'
    Write-Verbose 'provider-family-azure is healthy.'
}
catch {
    Write-Verbose "Failed to deploy provider-family-azure: $($_.Exception.Message)"
    throw
}

try {
    Write-Verbose 'Applying ProviderConfig...'
    kubectl apply -f "$GeneratedDir/providers/provider-config.yaml"
    Assert-ExitCode 'Failed to apply provider-config.yaml.'
    Write-Verbose 'ProviderConfig applied.'
}
catch {
    Write-Verbose "Failed to apply ProviderConfig: $($_.Exception.Message)"
    throw
}

try {
    Write-Verbose 'Applying provider-azure-storage...'
    kubectl apply -f "$GeneratedDir/providers/provider-azure-storage.yaml"
    Assert-ExitCode 'Failed to apply provider-azure-storage.yaml.'

    Write-Verbose 'Waiting for provider-azure-storage to become healthy...'
    Write-Progress -Id 1 -ParentId 0 -Activity 'Providers' -Status 'Waiting for provider-azure-storage to become healthy...' -PercentComplete 66 -ErrorAction SilentlyContinue
    kubectl wait --for=condition=Healthy providers.pkg.crossplane.io/provider-azure-storage --timeout=300s
    Assert-ExitCode 'provider-azure-storage did not become healthy within timeout.'
    Write-Verbose 'provider-azure-storage is healthy.'
}
catch {
    Write-Verbose "Failed to deploy provider-azure-storage: $($_.Exception.Message)"
    throw
}

Write-Progress -Id 1 -ParentId 0 -Activity 'Providers' -Completed -ErrorAction SilentlyContinue
Write-Progress -Id 0 -Activity 'Crossplane deployment' -Completed -ErrorAction SilentlyContinue

#endregion Part 6 - Applying Kubernetes manifests

Write-Verbose "All done. Elapsed time: $($ElapsedTime.Elapsed.ToString())."

Write-Host ''
Write-Host 'Crossplane is ready. To test with a Storage Account:' -ForegroundColor Green
Write-Host "  kubectl apply -f $GeneratedDir/examples/storage-account.yaml"
Write-Host '  kubectl get account.storage.azure.upbound.io -w'
Write-Host ''
Write-Host 'To clean up everything:'
Write-Host "  .\Deploy.ps1 -Cleanup"

<#
.SYNOPSIS
    Deploys the Radius-on-AKS-Automatic demo end to end.

.DESCRIPTION
    Automates: resource group creation, Bicep deployment, AKS credential setup,
    Radius installation via the rad CLI, Azure credential and environment
    configuration, and deployment of an example Radius application.

    Uses Azure PowerShell cmdlets (Az module) for all Azure operations — these
    throw terminating errors on failure, so the script halts immediately if
    anything goes wrong. External tools (kubectl, kubelogin, rad) are checked
    via exit code after each call.

    Original YAML files are left untouched — generated copies with real values
    are written to .generated/ and applied from there.

.PARAMETER ResourceGroupName
    Name of the Azure resource group. Default: rg-radius.

.PARAMETER Location
    Azure region for all resources. Default: swedencentral.

.PARAMETER SkipInfrastructure
    Skip Bicep deployment and resource group creation. Useful when re-running
    only the Kubernetes configuration steps against an existing cluster.

.PARAMETER Cleanup
    Tears down everything: deletes the Azure resource group (and all resources
    within it) and removes the local .generated/ folder.

.LINK
    https://docs.radapp.io/

.EXAMPLE
    .\Deploy.ps1
    .\Deploy.ps1 -SkipInfrastructure
    .\Deploy.ps1 -Cleanup
#>

[CmdletBinding()]
param(
    [string]$ResourceGroupName = 'rg-radius',
    [string]$Location = 'swedencentral',
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
        Assert-ExitCode 'rad install kubernetes failed.'
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
#               Part 1 - Deploying infrastructure                      #
########################################################################

#region Part 1 - Deploying infrastructure

Write-Progress -Id 0 -Activity 'Radius deployment' -Status 'Part 1 of 6 — Deploying infrastructure' -PercentComplete 0 -ErrorAction SilentlyContinue

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

Write-Progress -Id 0 -Activity 'Radius deployment' -Status 'Part 2 of 6 — Capturing deployment outputs' -PercentComplete 17 -ErrorAction SilentlyContinue
Write-Verbose 'Capturing deployment outputs...'

try {
    $Deployment = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name 'main' -ErrorAction Stop
    Write-Verbose 'Retrieved deployment outputs.'
}
catch {
    Write-Verbose "Failed to get deployment '$ResourceGroupName/main': $($_.Exception.Message)"
    throw
}

$ClusterName = $Deployment.Outputs['clusterName'].Value
$ClientId    = $Deployment.Outputs['radiusIdentityClientId'].Value

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
#             Part 3 - Generating Helm values                          #
########################################################################

#region Part 3 - Generating Helm values

Write-Progress -Id 0 -Activity 'Radius deployment' -Status 'Part 3 of 6 — Generating Helm values' -PercentComplete 33 -ErrorAction SilentlyContinue
Write-Verbose 'Generating Helm values...'

if (Test-Path $GeneratedDir) { Remove-Item $GeneratedDir -Recurse -Force }

Copy-Item -Path (Join-Path $ScriptRoot 'kubernetes') -Destination $GeneratedDir -Recurse

$YamlFiles = Get-ChildItem -Path $GeneratedDir -Recurse -Filter *.yaml

$Progress = 0
foreach ($File in $YamlFiles) {
    Write-Progress -Id 1 -ParentId 0 -Activity 'Processing YAML files' -Status $File.Name -PercentComplete ($Progress / $YamlFiles.Count * 100) -ErrorAction SilentlyContinue
    (Get-Content $File.FullName -Raw) `
        -replace '<RADIUS_IDENTITY_CLIENT_ID>', $ClientId |
        Set-Content $File.FullName
    $Progress++
}
Write-Progress -Id 1 -ParentId 0 -Activity 'Processing YAML files' -Completed -ErrorAction SilentlyContinue

Write-Verbose "Generated files in $GeneratedDir"

#endregion Part 3 - Generating Helm values

########################################################################
#              Part 4 - Connecting to cluster                          #
########################################################################

#region Part 4 - Connecting to cluster

Write-Progress -Id 0 -Activity 'Radius deployment' -Status 'Part 4 of 6 — Connecting to cluster' -PercentComplete 50 -ErrorAction SilentlyContinue
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
#              Part 5 - Installing Radius                              #
########################################################################

#region Part 5 - Installing Radius

Write-Progress -Id 0 -Activity 'Radius deployment' -Status 'Part 5 of 6 — Installing Radius' -PercentComplete 67 -ErrorAction SilentlyContinue
Write-Verbose 'Installing Radius...'

try {
    Write-Progress -Id 1 -ParentId 0 -Activity 'Radius install' -Status 'Running rad install kubernetes — this may take a while...' -PercentComplete 50 -ErrorAction SilentlyContinue
    rad install kubernetes --values "$GeneratedDir/radius/radius-values.yaml"
    Assert-ExitCode 'rad install kubernetes failed.'
    Write-Progress -Id 1 -ParentId 0 -Activity 'Radius install' -Completed -ErrorAction SilentlyContinue
    Write-Verbose 'Radius installed and ready.'
}
catch {
    Write-Verbose "Radius installation failed: $($_.Exception.Message)"
    throw
}

#endregion Part 5 - Installing Radius

########################################################################
#              Part 6 - Configuring Radius                             #
########################################################################

#region Part 6 - Configuring Radius

Write-Progress -Id 0 -Activity 'Radius deployment' -Status 'Part 6 of 6 — Configuring Radius' -PercentComplete 83 -ErrorAction SilentlyContinue

try {
    Write-Verbose 'Registering Azure credential (Workload Identity)...'
    rad credential register azure wi --client-id $ClientId --tenant-id $TenantId
    Assert-ExitCode 'rad credential register failed.'
    Write-Verbose 'Azure credential registered.'
}
catch {
    Write-Verbose "Failed to register Azure credential: $($_.Exception.Message)"
    throw
}

try {
    Write-Verbose 'Creating Radius environment...'
    rad env create dev --namespace default
    Assert-ExitCode 'rad env create failed.'

    Write-Verbose 'Configuring Azure cloud provider for environment...'
    rad env update dev `
        --azure-subscription-id $SubscriptionId `
        --azure-resource-group $ResourceGroupName
    Assert-ExitCode 'rad env update failed.'
    Write-Verbose 'Radius environment configured.'
}
catch {
    Write-Verbose "Failed to configure Radius environment: $($_.Exception.Message)"
    throw
}

Write-Progress -Id 0 -Activity 'Radius deployment' -Completed -ErrorAction SilentlyContinue

#endregion Part 6 - Configuring Radius

Write-Verbose "All done. Elapsed time: $($ElapsedTime.Elapsed.ToString())."

Write-Host ''
Write-Host 'Radius is ready. To deploy the example application:' -ForegroundColor Green
Write-Host "  rad deploy $ScriptRoot/kubernetes/examples/app.bicep --environment dev"
Write-Host '  rad app graph demo'
Write-Host ''
Write-Host 'To clean up everything:'
Write-Host "  .\Deploy.ps1 -Cleanup"

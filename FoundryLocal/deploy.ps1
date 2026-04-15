#Requires -Version 7.0
[CmdletBinding()]

<#
.SYNOPSIS
    Deploys Foundry Local with an Open WebUI chat interface.

.DESCRIPTION
    This script sets up Microsoft Foundry Local and Open WebUI for a local AI
    chat experience. It installs Foundry Local (if needed), downloads
    and loads an AI model, and launches Open WebUI via Docker for a browser-based
    chat interface. Everything runs on your device with no cloud dependency.

    Supports both Windows and macOS. The default model is qwen2.5-0.5b (the
    smallest available). Specify a different model with the -Model parameter.
    Run 'foundry model list' to see all available models after Foundry Local
    is installed.

.PARAMETER Model
    The Foundry Local model alias to download and load.
    Defaults to 'qwen2.5-0.5b' (smallest available model).
    Examples: 'phi-4-mini', 'phi-3.5-mini', 'deepseek-r1-7b'

.PARAMETER OpenWebUIPort
    The local port on which Open WebUI will be accessible.
    Defaults to 3000.

.PARAMETER SkipOpenWebUI
    If specified, only sets up Foundry Local without launching Open WebUI.
    Useful if you only want the Foundry Local service running.

.PARAMETER Cleanup
    If specified, tears down the demo environment: stops and removes the
    Open WebUI Docker container and volume, stops the Foundry Local service,
    and optionally uninstalls Foundry Local.

.LINK
    https://learn.microsoft.com/en-us/azure/foundry-local/what-is-foundry-local
    https://github.com/microsoft/Foundry-Local
    https://docs.openwebui.com/
#>

Param(
    [Parameter(HelpMessage = "Model alias to load (e.g., 'qwen2.5-0.5b', 'phi-4-mini')")]
    [string]$Model = "qwen2.5-0.5b",

    [Parameter(HelpMessage = "Local port for Open WebUI (default: 3000)")]
    [ValidateRange(1024, 65535)]
    [int]$OpenWebUIPort = 3000,

    [Parameter(HelpMessage = "Skip Open WebUI setup and only start Foundry Local")]
    [switch]$SkipOpenWebUI,

    [Parameter(HelpMessage = "Tear down the demo environment (remove containers, stop services)")]
    [switch]$Cleanup
)

#region Variables

$ContainerName = "open-webui-foundry"
$VolumeName = "open-webui-foundry"
$OpenWebUIImage = "ghcr.io/open-webui/open-webui:v0.8.6"

#endregion Variables

########################################################################
#                      DO NOT EDIT BELOW THIS LINE                     #
########################################################################

$ElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()

########################################################################
#                         Cleanup mode                                 #
########################################################################

if ($Cleanup) {
    Write-Host "Cleaning up Foundry Local demo environment..." -ForegroundColor Cyan

    # Stop and remove Open WebUI container and volume (only if Docker is available)
    $DockerCmdCleanup = Get-Command docker -ErrorAction SilentlyContinue
    if ($DockerCmdCleanup) {
        $ExistingContainer = docker ps -a --filter "name=$ContainerName" --format "{{.ID}}" 2>$null
        if ($ExistingContainer) {
            try {
                Write-Verbose "Stopping and removing Open WebUI container '$ContainerName'..."
                docker rm -f $ContainerName | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "docker rm exited with code $LASTEXITCODE."
                }
                Write-Host "  Removed Docker container '$ContainerName'." -ForegroundColor Green
            }
            catch {
                Write-Verbose "Failed to remove container: $_"
                Write-Host "  Could not remove container '$ContainerName'." -ForegroundColor Yellow
            }
        }
        else {
            Write-Verbose "No container named '$ContainerName' found."
            Write-Host "  No Open WebUI container found (already removed)." -ForegroundColor DarkGray
        }

        # Remove Open WebUI Docker volume
        $ExistingVolume = docker volume ls --filter "name=$VolumeName" --format "{{.Name}}" 2>$null
        if ($ExistingVolume) {
            $RemoveVolume = Read-Host "Remove Open WebUI data volume (deletes chat history)? (Y/N)"
            if ($RemoveVolume -eq 'Y' -or $RemoveVolume -eq 'y') {
                try {
                    Write-Verbose "Removing Docker volume '$VolumeName'..."
                    docker volume rm $VolumeName | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        throw "docker volume rm exited with code $LASTEXITCODE."
                    }
                    Write-Host "  Removed Docker volume '$VolumeName'." -ForegroundColor Green
                }
                catch {
                    Write-Verbose "Failed to remove volume: $_"
                    Write-Host "  Could not remove volume. It may still be in use." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "  Kept Docker volume (chat history preserved)." -ForegroundColor DarkGray
            }
        }
    }
    else {
        Write-Verbose "Docker not found in PATH; skipping container and volume cleanup."
        Write-Host "  Docker not available — skipped container/volume cleanup." -ForegroundColor DarkGray
    }

    # Stop Foundry Local service
    $StopTempErr = [System.IO.Path]::GetTempFileName()
    try {
        Write-Verbose "Stopping Foundry Local service..."
        $StopProc = Start-Process -FilePath "foundry" -ArgumentList "service","stop" -NoNewWindow -Wait -PassThru -RedirectStandardError $StopTempErr
        if ($StopProc.ExitCode -ne 0) {
            throw "foundry service stop exited with code $($StopProc.ExitCode)."
        }
        Write-Verbose "Successfully stopped Foundry Local service."
        Write-Host "  Stopped Foundry Local service." -ForegroundColor Green
    }
    catch {
        Write-Verbose "Foundry service stop failed (may not be running): $_"
        Write-Host "  Foundry Local service was not running." -ForegroundColor DarkGray
    }
    finally {
        Remove-Item $StopTempErr -ErrorAction SilentlyContinue
    }

    # Offer to remove cached model
    try {
        $TempCacheOut = [System.IO.Path]::GetTempFileName()
        $TempCacheErr = [System.IO.Path]::GetTempFileName()
        $CacheProc = Start-Process -FilePath "foundry" -ArgumentList "cache","list" -NoNewWindow -PassThru -RedirectStandardOutput $TempCacheOut -RedirectStandardError $TempCacheErr
        $CacheExited = $CacheProc.WaitForExit(10000)
        if (-not $CacheExited) {
            $CacheProc.Kill()
            Write-Verbose "foundry cache list timed out."
            $CacheOutput = ""
        }
        else {
            $CacheOutput = Get-Content $TempCacheOut -Raw -ErrorAction SilentlyContinue
        }
        Remove-Item $TempCacheOut, $TempCacheErr -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Verbose "Failed to query model cache: $_"
        $CacheOutput = ""
    }

    $EscapedModel = [regex]::Escape($Model)
    if ($CacheOutput -and $CacheOutput -match $EscapedModel) {
        $RemoveModel = Read-Host "Remove cached model '$Model' from disk? (Y/N)"
        if ($RemoveModel -eq 'Y' -or $RemoveModel -eq 'y') {
            try {
                Write-Verbose "Removing model '$Model' from cache..."
                $RemoveCacheProc = Start-Process -FilePath "foundry" -ArgumentList "cache", "rm", $Model -NoNewWindow -PassThru
                $null = $RemoveCacheProc.WaitForExit()
                if ($RemoveCacheProc.ExitCode -eq 0) {
                    Write-Verbose "Successfully removed model '$Model' from cache."
                    Write-Host "  Removed model '$Model' from cache." -ForegroundColor Green
                }
                else {
                    Write-Verbose "Failed to remove model '$Model' from cache. foundry exited with code $($RemoveCacheProc.ExitCode)."
                    Write-Host "  Could not remove model from cache." -ForegroundColor Yellow
                }
            }
            catch {
                Write-Verbose "Failed to remove model from cache: $_"
                Write-Host "  Could not remove model from cache." -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "  Kept model '$Model' in cache." -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "  No cached model '$Model' found." -ForegroundColor DarkGray
    }

    # Uninstall Foundry Local
    $FoundryCmd = Get-Command foundry -ErrorAction SilentlyContinue
    if ($FoundryCmd) {
        $RemoveFoundry = Read-Host "Uninstall Foundry Local? (Y/N)"
        if ($RemoveFoundry -eq 'Y' -or $RemoveFoundry -eq 'y') {
            Write-Verbose "Detecting operating system for uninstall..."
            if ($IsWindows) {
                try {
                    Write-Verbose "Uninstalling Foundry Local via winget..."
                    winget uninstall Microsoft.FoundryLocal --accept-source-agreements
                    if ($LASTEXITCODE -ne 0) { throw "winget uninstall exited with code $LASTEXITCODE" }
                    Write-Host "  Uninstalled Foundry Local." -ForegroundColor Green
                }
                catch {
                    Write-Verbose "winget uninstall failed: $_"
                    Write-Host "  Could not uninstall Foundry Local. Try: winget uninstall Microsoft.FoundryLocal" -ForegroundColor Yellow
                }
            }
            elseif ($IsMacOS) {
                try {
                    Write-Verbose "Uninstalling Foundry Local via Homebrew..."
                    brew uninstall foundrylocal
                    if ($LASTEXITCODE -ne 0) { throw "brew uninstall exited with code $LASTEXITCODE" }
                    Write-Host "  Uninstalled Foundry Local." -ForegroundColor Green
                }
                catch {
                    Write-Verbose "brew uninstall failed: $_"
                    Write-Host "  Could not uninstall Foundry Local. Try: brew uninstall foundrylocal" -ForegroundColor Yellow
                }
            }
        }
        else {
            Write-Host "  Kept Foundry Local installed." -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "  Foundry Local not found (already uninstalled)." -ForegroundColor DarkGray
    }

    # Uninstall Docker Desktop
    $DockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if ($DockerCmd) {
        $RemoveDocker = Read-Host "Uninstall Docker Desktop? (Y/N)"
        if ($RemoveDocker -eq 'Y' -or $RemoveDocker -eq 'y') {
            Write-Verbose "Detecting operating system for Docker uninstall..."
            if ($IsWindows) {
                try {
                    Write-Verbose "Uninstalling Docker Desktop via winget..."
                    winget uninstall Docker.DockerDesktop --accept-source-agreements
                    if ($LASTEXITCODE -ne 0) { throw "winget uninstall exited with code $LASTEXITCODE" }
                    Write-Host "  Uninstalled Docker Desktop." -ForegroundColor Green
                }
                catch {
                    Write-Verbose "winget uninstall failed: $_"
                    Write-Host "  Could not uninstall Docker Desktop. Try: winget uninstall Docker.DockerDesktop" -ForegroundColor Yellow
                }
            }
            elseif ($IsMacOS) {
                try {
                    Write-Verbose "Uninstalling Docker Desktop via Homebrew..."
                    brew uninstall --cask docker
                    if ($LASTEXITCODE -ne 0) { throw "brew uninstall exited with code $LASTEXITCODE" }
                    Write-Host "  Uninstalled Docker Desktop." -ForegroundColor Green
                }
                catch {
                    Write-Verbose "brew uninstall failed: $_"
                    Write-Host "  Could not uninstall Docker Desktop. Try: brew uninstall --cask docker" -ForegroundColor Yellow
                }
            }
        }
        else {
            Write-Host "  Kept Docker Desktop installed." -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "  Docker Desktop not found (already uninstalled)." -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "Cleanup complete." -ForegroundColor Green
    Write-Host "Elapsed time: $($ElapsedTime.Elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor DarkGray
    exit 0
}

########################################################################
#                         Part 1 - Prerequisites                       #
########################################################################

Write-Verbose "Detecting operating system..."
if ($IsWindows) {
    $Platform = "Windows"
} elseif ($IsMacOS) {
    $Platform = "macOS"
} else {
    Write-Error "This script supports Windows and macOS only."
    exit 1
}
Write-Verbose "Running on $Platform."

# Check Docker (required for Open WebUI)
if (-not $SkipOpenWebUI) {
    Write-Verbose "Checking for Docker..."
    $DockerReady = $false

    # First check if docker CLI is available
    $DockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if ($DockerCmd) {
        Write-Verbose "Docker CLI found at $($DockerCmd.Source)."
        # Then check if the engine is running
        try {
            $DockerInfo = docker info 2>&1
            if ($LASTEXITCODE -eq 0) {
                $DockerReady = $true
                Write-Verbose "Docker engine is running."
            } else {
                Write-Verbose "Docker CLI found but engine is not running."
            }
        }
        catch {
            Write-Verbose "Docker engine check failed: $_"
        }
    } else {
        Write-Verbose "Docker CLI not found in PATH."
    }

    if (-not $DockerReady) {
        # Distinguish between "not installed" and "installed but not running"
        $DockerInstalled = [bool]$DockerCmd

        if (-not $DockerInstalled) {
            # Docker CLI not found — offer to install
            Write-Host "Docker Desktop is required for Open WebUI but was not detected." -ForegroundColor Yellow
            Write-Host "  (If you recently installed Docker, try restarting your terminal first.)" -ForegroundColor DarkGray
            $Install = Read-Host "Would you like to install Docker Desktop now? (Y/N)"
            if ($Install -eq 'Y' -or $Install -eq 'y') {
                Write-Host "Installing Docker Desktop..." -ForegroundColor Cyan
                if ($Platform -eq "Windows") {
                    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                        Write-Error "winget is required to install Docker Desktop but was not found. Install winget from https://learn.microsoft.com/en-us/windows/package-manager/winget/ and re-run this script."
                        exit 1
                    }
                    try {
                        Write-Verbose "Installing Docker Desktop via winget..."
                        winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
                        if ($LASTEXITCODE -ne 0) { throw "winget install exited with code $LASTEXITCODE" }
                        Write-Verbose "Docker Desktop installed via winget."
                    }
                    catch {
                        Write-Verbose "Docker Desktop winget installation failed: $_"
                        throw
                    }
                }
                elseif ($Platform -eq "macOS") {
                    if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
                        Write-Error "Homebrew (brew) is required to install Docker Desktop but was not found. Install Homebrew from https://brew.sh/ and re-run this script."
                        exit 1
                    }
                    try {
                        Write-Verbose "Installing Docker Desktop via Homebrew cask..."
                        brew install --cask docker
                        if ($LASTEXITCODE -ne 0) { throw "brew install exited with code $LASTEXITCODE" }
                        Write-Verbose "Docker Desktop installed via Homebrew."
                    }
                    catch {
                        Write-Verbose "Docker Desktop Homebrew installation failed: $_"
                        throw
                    }
                }
            }
            else {
                Write-Host "Skipping Docker install. Use -SkipOpenWebUI to run Foundry Local without the web interface." -ForegroundColor DarkGray
                exit 1
            }
        }
        else {
            # Docker is installed but engine isn't running
            Write-Host "Docker Desktop is installed but the engine is not running." -ForegroundColor Yellow
        }

        # Launch Docker Desktop and wait for the engine to be ready
        Write-Host "Starting Docker Desktop..." -ForegroundColor Cyan
        if ($Platform -eq "Windows") {
            $DockerPath = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
            if (Test-Path $DockerPath) {
                Start-Process $DockerPath
            }
            else {
                Write-Verbose "Docker Desktop executable not found at expected path, trying shell start..."
                Start-Process "Docker Desktop"
            }
        }
        elseif ($Platform -eq "macOS") {
            open -a Docker
        }

        Write-Host "  Waiting for Docker engine to be ready (up to 5 minutes)..." -ForegroundColor DarkGray
        $DockerMaxRetries = 100
        $DockerRetry = 0
        $DockerCheckTimeout = 5000 # milliseconds per check
        while ($DockerRetry -lt $DockerMaxRetries) {
            try {
                # Run docker info with a per-check timeout to avoid hanging when engine is stuck
                $TempOut = [System.IO.Path]::GetTempFileName()
                $TempErr = [System.IO.Path]::GetTempFileName()
                $Proc = Start-Process -FilePath "docker" -ArgumentList "info" -NoNewWindow -PassThru -RedirectStandardOutput $TempOut -RedirectStandardError $TempErr
                $Exited = $Proc.WaitForExit($DockerCheckTimeout)
                if ($Exited -and $Proc.ExitCode -eq 0) {
                    Write-Verbose "Docker engine is ready."
                    $DockerReady = $true
                    break
                }
                if (-not $Exited) {
                    Write-Verbose "Docker info check timed out (attempt $($DockerRetry + 1)), retrying..."
                    $Proc.Kill()
                }
            }
            catch {
                # Not ready yet
            }
            finally {
                Remove-Item $TempOut, $TempErr -Force -ErrorAction SilentlyContinue
            }
            $DockerRetry++
            Start-Sleep -Seconds 3
        }

        if (-not $DockerReady) {
            Write-Error "Docker Desktop engine did not start within 5 minutes. Please launch Docker Desktop manually and re-run this script."
            exit 1
        }
        Write-Host "Docker Desktop is running." -ForegroundColor Green
    }
}

########################################################################
#                  Part 2 - Install Foundry Local                   #
########################################################################

Write-Verbose "Checking if Foundry Local is installed..."
$FoundryInstalled = $false
try {
    $FoundryVersion = foundry --version 2>$null
    if ($FoundryVersion) {
        $FoundryInstalled = $true
        Write-Verbose "Foundry Local is already installed: $FoundryVersion"
    }
}
catch {
    Write-Verbose "Foundry Local not found."
}

if (-not $FoundryInstalled) {
    Write-Host "Installing Foundry Local..." -ForegroundColor Cyan
    if ($Platform -eq "Windows") {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Error "winget is required to install Foundry Local but was not found. Install winget from https://learn.microsoft.com/en-us/windows/package-manager/winget/ and re-run this script."
            exit 1
        }
        try {
            Write-Verbose "Installing via winget..."
            winget install Microsoft.FoundryLocal --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0) { throw "winget install exited with code $LASTEXITCODE" }
            Write-Verbose "Foundry Local installed via winget."
        }
        catch {
            Write-Verbose "winget installation failed: $_"
            throw
        }
    }
    elseif ($Platform -eq "macOS") {
        if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
            Write-Error "Homebrew (brew) is required to install Foundry Local but was not found. Install Homebrew from https://brew.sh/ and re-run this script."
            exit 1
        }
        try {
            Write-Verbose "Adding the Microsoft Foundry Local Homebrew tap..."
            brew tap microsoft/foundrylocal
            if ($LASTEXITCODE -ne 0) { throw "brew tap exited with code $LASTEXITCODE" }
            Write-Verbose "Microsoft Foundry Local Homebrew tap added."
        }
        catch {
            Write-Verbose "Homebrew tap failed: $_"
            throw
        }
        try {
            Write-Verbose "Installing Foundry Local via Homebrew..."
            brew install foundrylocal
            if ($LASTEXITCODE -ne 0) { throw "brew install exited with code $LASTEXITCODE" }
            Write-Verbose "Foundry Local installed via Homebrew."
        }
        catch {
            Write-Verbose "Homebrew install failed: $_"
            throw
        }
    }

    # Verify installation
    try {
        $FoundryVersion = foundry --version
        Write-Host "Foundry Local installed: $FoundryVersion" -ForegroundColor Green
    }
    catch {
        Write-Verbose "Post-install verification failed: $_"
        Write-Error "Foundry Local installation could not be verified. You may need to restart your terminal and try again."
        exit 1
    }
}

########################################################################
#          Part 3 - Start Foundry Local service and load model         #
########################################################################

Write-Host "Starting Foundry Local service..." -ForegroundColor Cyan
Write-Verbose "Starting Foundry Local service (timeout: 3 minutes)..."

$ServiceStarted = $false
$ServiceCommands = @("start", "restart")
foreach ($ServiceAction in $ServiceCommands) {
    Write-Verbose "Attempting 'foundry service $ServiceAction'..."
    $TempOut = [System.IO.Path]::GetTempFileName()
    $TempErr = [System.IO.Path]::GetTempFileName()
    try {
        $Proc = Start-Process -FilePath "foundry" -ArgumentList "service", $ServiceAction `
            -RedirectStandardOutput $TempOut -RedirectStandardError $TempErr `
            -PassThru -NoNewWindow
        # Wait up to 3 minutes for the service to start
        $ServiceTimeout = 180
        $Waited = 0
        while (-not $Proc.HasExited -and $Waited -lt $ServiceTimeout) {
            Start-Sleep -Seconds 2
            $Waited += 2
            if ($Waited % 10 -eq 0) {
                Write-Host "  Still waiting for Foundry Local service to $ServiceAction... ($Waited`s)" -ForegroundColor DarkGray
            }
        }
        if (-not $Proc.HasExited) {
            Write-Verbose "foundry service $ServiceAction timed out after $ServiceTimeout seconds, killing process."
            $Proc.Kill()
            $Proc.WaitForExit()
            continue
        }
        if ($Proc.ExitCode -eq 0) {
            $ServiceStarted = $true
            Write-Verbose "Foundry Local service $($ServiceAction) succeeded."
            Write-Host "Foundry Local service is running." -ForegroundColor Green
            break
        }
        else {
            Write-Verbose "foundry service $ServiceAction exited with code $($Proc.ExitCode)."
        }
    }
    catch {
        Write-Verbose "foundry service $ServiceAction failed: $_"
    }
    finally {
        Remove-Item $TempOut -ErrorAction SilentlyContinue
        Remove-Item $TempErr -ErrorAction SilentlyContinue
    }
}

if (-not $ServiceStarted) {
    Write-Error "Failed to start Foundry Local service. Try running 'foundry service start' manually."
    exit 1
}

# Check if the model is already cached locally
Write-Verbose "Checking whether model '$Model' is already present in the local cache..."
$CacheTempOut = [System.IO.Path]::GetTempFileName()
$CacheTempErr = [System.IO.Path]::GetTempFileName()
$CacheOutput = ""
try {
    Write-Verbose "Running 'foundry cache list'..."
    $CacheProc = Start-Process -FilePath "foundry" -ArgumentList "cache", "list" `
        -RedirectStandardOutput $CacheTempOut -RedirectStandardError $CacheTempErr `
        -PassThru -NoNewWindow
    $CacheExited = $CacheProc.WaitForExit(60000)
    if (-not $CacheExited) {
        Write-Verbose "foundry cache list timed out after 60 seconds, killing process."
        $CacheProc.Kill()
        $CacheProc.WaitForExit()
        throw "foundry cache list timed out after 60 seconds."
    }
    if ($CacheProc.ExitCode -ne 0) {
        $CacheError = Get-Content -Path $CacheTempErr -Raw -ErrorAction SilentlyContinue
        throw "foundry cache list exited with code $($CacheProc.ExitCode): $CacheError"
    }
    $CacheOutput = Get-Content -Path $CacheTempOut -Raw -ErrorAction SilentlyContinue
    Write-Verbose "'foundry cache list' completed successfully."
}
catch {
    Write-Verbose "Cache check failed: $_"
    Write-Error "Failed to query the local Foundry cache. Ensure the Foundry Local service is ready, then try again."
    exit 1
}
finally {
    Remove-Item $CacheTempOut, $CacheTempErr -ErrorAction SilentlyContinue
}

if ($CacheOutput | Select-String -SimpleMatch -Pattern $Model -Quiet) {
    Write-Verbose "Model '$Model' was found in the local cache."
    Write-Host "Model '$Model' is already downloaded." -ForegroundColor Green
}
else {
    Write-Verbose "Model '$Model' was not found in the local cache."
    Write-Host "Downloading model '$Model'..." -ForegroundColor Cyan
    Write-Host "  (This may take several minutes on first run depending on your connection)" -ForegroundColor DarkGray
    Write-Host "  Tip: Run 'foundry cache list' in another terminal to check download status." -ForegroundColor DarkGray
    try {
        Write-Verbose "Running 'foundry model download $Model'..."
        foundry model download $Model
        if ($LASTEXITCODE -ne 0) { throw "foundry model download exited with code $LASTEXITCODE" }
        Write-Verbose "Model '$Model' downloaded successfully."
        Write-Host "Model '$Model' downloaded." -ForegroundColor Green
    }
    catch {
        Write-Verbose "Model download failed: $_"
        Write-Error "Failed to download model '$Model'. Run 'foundry model list' to see available models."
        exit 1
    }
}

Write-Host "Loading model '$Model' into Foundry Local service..." -ForegroundColor Cyan
try {
    Write-Verbose "Running 'foundry model load $Model'..."
    foundry model load $Model
    if ($LASTEXITCODE -ne 0) { throw "foundry model load exited with code $LASTEXITCODE" }
    Write-Verbose "Model '$Model' loaded successfully."
    Write-Host "Model '$Model' is ready." -ForegroundColor Green
}
catch {
    Write-Verbose "Model load failed: $_"
    Write-Error "Failed to load model '$Model'. Run 'foundry model list' to see available models."
    exit 1
}

########################################################################
#              Part 4 - Get Foundry Local endpoint                     #
########################################################################

Write-Host "Getting Foundry Local endpoint..." -ForegroundColor Cyan
try {
    Write-Verbose "Querying Foundry Local service status..."
    $ServiceOutput = foundry service status 2>&1 | Out-String
    Write-Verbose "Service status output: $ServiceOutput"

    # Extract the endpoint URL exactly as reported by the service so the scheme and host are preserved.
    if ($ServiceOutput -match '(https?://[^/\s]+:(\d+))') {
        $FoundryEndpoint = $Matches[1]
        $FoundryPort = $Matches[2]
        Write-Verbose "Foundry Local endpoint detected from service status: $FoundryEndpoint"
        Write-Host "Foundry Local running at $FoundryEndpoint" -ForegroundColor Green
    }
    else {
        throw "Could not parse the Foundry Local endpoint from service status output."
    }
}
catch {
    Write-Verbose "Endpoint detection failed: $_"
    Write-Error "Failed to determine Foundry Local endpoint. Run 'foundry service status' manually to check."
    exit 1
}

if ($SkipOpenWebUI) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Foundry Local is ready!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Endpoint : $FoundryEndpoint" -ForegroundColor White
    Write-Host " Model    : $Model" -ForegroundColor White
    Write-Host ""
    Write-Host " Test it with:" -ForegroundColor DarkGray
    Write-Host "   foundry model run $Model" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Elapsed time: $($ElapsedTime.Elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor DarkGray
    exit 0
}

########################################################################
#                     Part 5 - Launch Open WebUI                       #
########################################################################

# The Docker container needs to reach the host — use host.docker.internal
$FoundryDockerEndpoint = "http://host.docker.internal:$FoundryPort/v1"

Write-Host "Setting up Open WebUI..." -ForegroundColor Cyan

# Remove any existing container with the same name
try {
    Write-Verbose "Checking for existing '$ContainerName' container..."
    $ExistingContainer = docker ps -a --filter "name=$ContainerName" --format '{{.Names}}' 2>$null
    if ($ExistingContainer -eq $ContainerName) {
        Write-Verbose "Removing existing container '$ContainerName'..."
        docker rm -f $ContainerName 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "docker rm -f exited with code $LASTEXITCODE"
        }
        Write-Verbose "Existing container removed."
    }
}
catch {
    Write-Verbose "Container cleanup check failed (non-fatal): $_"
}

# Pull the Open WebUI image
try {
    Write-Verbose "Pulling Open WebUI Docker image..."
    Write-Host "  Pulling Open WebUI image (this may take a moment)..." -ForegroundColor DarkGray
    docker pull $OpenWebUIImage
    if ($LASTEXITCODE -ne 0) { throw "docker pull exited with code $LASTEXITCODE" }
    Write-Verbose "Open WebUI image pulled successfully."
}
catch {
    Write-Verbose "Docker pull failed: $_"
    throw
}

# Start the container
# DEMO SHORTCUT: WEBUI_AUTH=False disables authentication for demo simplicity.
# This is NOT suitable for production use — always enable auth in real deployments.
try {
    Write-Verbose "Starting Open WebUI container on port $OpenWebUIPort..."
    docker run -d `
        -p "$($OpenWebUIPort):8080" `
        -e "OPENAI_API_BASE_URLS=$FoundryDockerEndpoint" `
        -e "OPENAI_API_KEYS=OPENAI_API_KEY" `
        -e "WEBUI_AUTH=False" `
        -v "$($VolumeName):/app/backend/data" `
        --name $ContainerName `
        --add-host "host.docker.internal:host-gateway" `
        $OpenWebUIImage | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "docker run exited with code $LASTEXITCODE" }
    Write-Verbose "Open WebUI container started."
}
catch {
    Write-Verbose "Failed to start Open WebUI container: $_"
    throw
}

# Wait for Open WebUI to become responsive
Write-Host "  Waiting for Open WebUI to start..." -ForegroundColor DarkGray
$MaxRetries = 30
$RetryCount = 0
$WebUIReady = $false
while ($RetryCount -lt $MaxRetries) {
    try {
        $Response = Invoke-WebRequest -Uri "http://localhost:$OpenWebUIPort" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($Response.StatusCode -eq 200) {
            $WebUIReady = $true
            break
        }
    }
    catch {
        # Not ready yet
    }
    $RetryCount++
    Start-Sleep -Seconds 2
}

if (-not $WebUIReady) {
    Write-Host "  Open WebUI may still be starting up. Check http://localhost:$OpenWebUIPort in a moment." -ForegroundColor Yellow
} else {
    Write-Verbose "Open WebUI is responsive."
}

########################################################################
#                       Part 6 - Open browser                         #
########################################################################

$WebUIUrl = "http://localhost:$OpenWebUIPort"
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Foundry Local + Open WebUI is ready!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host " Open WebUI : $WebUIUrl" -ForegroundColor White
Write-Host " Foundry API: $FoundryEndpoint" -ForegroundColor White
Write-Host " Model      : $Model" -ForegroundColor White
Write-Host ""
Write-Host " If the model does not appear in Open WebUI," -ForegroundColor DarkGray
Write-Host " add a Direct Connection in Settings > Connections:" -ForegroundColor DarkGray
Write-Host "   URL : http://host.docker.internal:$FoundryPort/v1" -ForegroundColor DarkGray
Write-Host "   Auth: None" -ForegroundColor DarkGray
Write-Host ""
Write-Host " To stop: docker rm -f $ContainerName && foundry service stop" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Elapsed time: $($ElapsedTime.Elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor DarkGray

# Open the browser
try {
    Write-Verbose "Opening browser to $WebUIUrl..."
    if ($Platform -eq "Windows") {
        Start-Process $WebUIUrl
    }
    elseif ($Platform -eq "macOS") {
        open $WebUIUrl
    }
}
catch {
    Write-Verbose "Could not auto-open browser: $_"
    Write-Host "Open your browser to $WebUIUrl" -ForegroundColor Yellow
}

#Requires -Version 7.0
[CmdletBinding()]

<#
.SYNOPSIS
    Deploys Foundry Local with an Open WebUI chat interface.

.DESCRIPTION
    This script sets up Microsoft Foundry Local and Open WebUI for a local AI
    chat experience. It installs the Foundry Local CLI (if needed), downloads
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
    [switch]$SkipOpenWebUI
)

#region Variables

$ContainerName = "open-webui-foundry"
$OpenWebUIImage = "ghcr.io/open-webui/open-webui:main"

#endregion Variables

########################################################################
#                      DO NOT EDIT BELOW THIS LINE                     #
########################################################################

$ElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()

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
    try {
        $DockerVersion = docker version --format '{{.Server.Version}}' 2>$null
        if ($DockerVersion) {
            $DockerReady = $true
            Write-Verbose "Docker version $DockerVersion found."
        }
    }
    catch {
        Write-Verbose "Docker not found or not running."
    }

    if (-not $DockerReady) {
        Write-Host "Docker Desktop is required for Open WebUI but was not detected." -ForegroundColor Yellow
        $Install = Read-Host "Would you like to install Docker Desktop now? (Y/N)"
        if ($Install -eq 'Y' -or $Install -eq 'y') {
            Write-Host "Installing Docker Desktop..." -ForegroundColor Cyan
            if ($Platform -eq "Windows") {
                try {
                    Write-Verbose "Installing Docker Desktop via winget..."
                    winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
                    Write-Verbose "Docker Desktop installed via winget."
                }
                catch {
                    Write-Verbose "Docker Desktop winget installation failed: $_"
                    throw
                }
            }
            elseif ($Platform -eq "macOS") {
                try {
                    Write-Verbose "Installing Docker Desktop via Homebrew cask..."
                    brew install --cask docker
                    Write-Verbose "Docker Desktop installed via Homebrew."
                }
                catch {
                    Write-Verbose "Docker Desktop Homebrew installation failed: $_"
                    throw
                }
            }
            # Launch Docker Desktop and wait for the engine to be ready
            Write-Host "Starting Docker Desktop..." -ForegroundColor Cyan
            if ($Platform -eq "Windows") {
                $DockerPath = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
                if (Test-Path $DockerPath) {
                    Start-Process $DockerPath
                } else {
                    Write-Verbose "Docker Desktop executable not found at expected path, trying shell start..."
                    Start-Process "Docker Desktop"
                }
            }
            elseif ($Platform -eq "macOS") {
                open -a Docker
            }

            Write-Host "  Waiting for Docker engine to be ready..." -ForegroundColor DarkGray
            $DockerMaxRetries = 60
            $DockerRetry = 0
            while ($DockerRetry -lt $DockerMaxRetries) {
                try {
                    $DockerVersion = docker version --format '{{.Server.Version}}' 2>$null
                    if ($DockerVersion) {
                        Write-Verbose "Docker engine is ready (version $DockerVersion)."
                        $DockerReady = $true
                        break
                    }
                }
                catch {
                    # Not ready yet
                }
                $DockerRetry++
                Start-Sleep -Seconds 3
            }

            if (-not $DockerReady) {
                Write-Error "Docker Desktop was installed but the engine did not start within 3 minutes. Please launch Docker Desktop manually and re-run this script."
                exit 1
            }
            Write-Host "Docker Desktop is running." -ForegroundColor Green
        }
        else {
            Write-Host "Skipping Docker install. Use -SkipOpenWebUI to run Foundry Local without the web interface." -ForegroundColor DarkGray
            exit 1
        }
    }
}

########################################################################
#                  Part 2 - Install Foundry Local CLI                   #
########################################################################

Write-Verbose "Checking if Foundry Local CLI is installed..."
$FoundryInstalled = $false
try {
    $FoundryVersion = foundry --version 2>$null
    if ($FoundryVersion) {
        $FoundryInstalled = $true
        Write-Verbose "Foundry Local CLI is already installed: $FoundryVersion"
    }
}
catch {
    Write-Verbose "Foundry Local CLI not found."
}

if (-not $FoundryInstalled) {
    Write-Host "Installing Foundry Local CLI..." -ForegroundColor Cyan
    if ($Platform -eq "Windows") {
        try {
            Write-Verbose "Installing via winget..."
            winget install Microsoft.FoundryLocal --accept-source-agreements --accept-package-agreements
            Write-Verbose "Foundry Local CLI installed via winget."
        }
        catch {
            Write-Verbose "winget installation failed: $_"
            throw
        }
    }
    elseif ($Platform -eq "macOS") {
        try {
            Write-Verbose "Installing via Homebrew..."
            brew tap microsoft/foundrylocal
            brew install foundrylocal
            Write-Verbose "Foundry Local CLI installed via Homebrew."
        }
        catch {
            Write-Verbose "Homebrew installation failed: $_"
            throw
        }
    }

    # Verify installation
    try {
        $FoundryVersion = foundry --version
        Write-Host "Foundry Local CLI installed: $FoundryVersion" -ForegroundColor Green
    }
    catch {
        Write-Verbose "Post-install verification failed: $_"
        Write-Error "Foundry Local CLI installation could not be verified. You may need to restart your terminal and try again."
        exit 1
    }
}

########################################################################
#          Part 3 - Start Foundry Local service and load model         #
########################################################################

Write-Host "Starting Foundry Local service..." -ForegroundColor Cyan
try {
    Write-Verbose "Restarting Foundry Local service to ensure a clean state..."
    foundry service start 2>$null
    Write-Verbose "Foundry Local service started."
}
catch {
    Write-Verbose "Service start attempt failed, trying restart: $_"
    try {
        foundry service restart
        Write-Verbose "Foundry Local service restarted successfully."
    }
    catch {
        Write-Verbose "Service restart also failed: $_"
        throw
    }
}

Write-Host "Downloading and loading model '$Model'..." -ForegroundColor Cyan
Write-Host "  (This may take a while on first run as the model is downloaded)" -ForegroundColor DarkGray
try {
    Write-Verbose "Running 'foundry model load $Model'..."
    foundry model download $Model
    foundry model load $Model
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

    # Extract the endpoint URL (e.g., http://127.0.0.1:XXXXX or http://localhost:XXXXX)
    if ($ServiceOutput -match 'https?://[^/\s]+:(\d+)') {
        $FoundryPort = $Matches[1]
        $FoundryEndpoint = "http://127.0.0.1:$FoundryPort"
        Write-Verbose "Foundry Local endpoint: $FoundryEndpoint"
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
        -v "open-webui-foundry:/app/backend/data" `
        --name $ContainerName `
        --add-host "host.docker.internal:host-gateway" `
        $OpenWebUIImage | Out-Null
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

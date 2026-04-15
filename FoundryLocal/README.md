# Foundry Local + Open WebUI Demo

Run AI models locally on your device with a browser-based chat interface — no cloud, no API keys, no subscriptions.

This demo uses [Microsoft Foundry Local](https://learn.microsoft.com/en-us/azure/foundry-local/what-is-foundry-local) as the local AI runtime and [Open WebUI](https://docs.openwebui.com/) as the chat interface.

## Prerequisites

| Requirement | Windows | macOS |
|---|---|---|
| **PowerShell 7+** | [Install](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows) | [Install](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos) |

> **Note:** Foundry Local and Docker Desktop (when needed) are installed automatically by the script (`winget` on Windows, `brew` on macOS).

## Quick Start

```powershell
.\deploy.ps1
```

That's it. The script will:

1. Install Foundry Local (if not already installed)
2. Start the Foundry Local service
3. Download and load the default model (`qwen2.5-0.5b`, ~500M params)
4. Launch Open WebUI in a Docker container
5. Open your browser to <http://localhost:3000>

## Using a Different Model

Specify a model alias with the `-Model` parameter:

```powershell
.\deploy.ps1 -Model phi-4-mini
.\deploy.ps1 -Model phi-3.5-mini
.\deploy.ps1 -Model deepseek-r1-7b
```

To see all available models:

```powershell
foundry model list
```

## Options

| Parameter | Default | Description |
|---|---|---|
| `-Model` | `qwen2.5-0.5b` | Model alias to load |
| `-OpenWebUIPort` | `3000` | Local port for the web UI |
| `-SkipOpenWebUI` | — | Only start Foundry Local (no web UI) |
| `-SkipOpenWebUI` | — | Only start Foundry Local (no web UI) |
| `-Cleanup` | — | Stop and remove the local demo resources created by the script |

### Examples

```powershell
# Use verbose output to see what's happening
.\deploy.ps1 -Verbose

# Run on a custom port
.\deploy.ps1 -OpenWebUIPort 8080

# Only start Foundry Local without the web UI
.\deploy.ps1 -SkipOpenWebUI
```

## Troubleshooting

### Models don't appear in Open WebUI

If the model dropdown is empty, add a Direct Connection manually:

1. Open **Settings** → **Connections** → **Manage Direct Connections**
2. Click **+**
3. Set **URL** to `http://host.docker.internal:<PORT>/v1` (get the port from `foundry service status`)
4. Set **Auth** to **None**
5. Click **Save**

### Foundry Local service errors

```powershell
foundry service restart
foundry service status
```

### Check loaded models

```powershell
foundry service ps
```

## Cleanup

Use the `-Cleanup` switch to stop and remove everything:

```powershell
.\deploy.ps1 -Cleanup
```

## How It Works

```
┌─────────────────────┐     ┌──────────────────────────┐
│                     │     │                          │
│   Open WebUI        │────▶│   Foundry Local Service  │
│   (Docker, :3000)   │     │   (host, dynamic port)   │
│                     │     │                          │
│   Browser chat UI   │     │   OpenAI-compatible API  │
│                     │     │   Model inference (ONNX) │
└─────────────────────┘     └──────────────────────────┘
        ▲                              │
        │                              ▼
   You (browser)              Local AI model
                              (qwen2.5-0.5b, etc.)
```

- **Foundry Local** handles model management, hardware acceleration (GPU/NPU/CPU), and serves an OpenAI-compatible API
- **Open WebUI** provides a polished chat interface that connects to the Foundry Local API
- All data stays on your device — nothing is sent to the cloud

## Links

- [Foundry Local Documentation](https://learn.microsoft.com/en-us/azure/foundry-local/)
- [Foundry Local GitHub](https://github.com/microsoft/Foundry-Local)
- [Open WebUI Documentation](https://docs.openwebui.com/)
- [Foundry Local CLI Reference](https://learn.microsoft.com/en-us/azure/foundry-local/reference/reference-cli)

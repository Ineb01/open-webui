# open-webui

ArgoCD deployment configuration for Open WebUI with MCP (Model Context Protocol) integration.

## Overview

This repository contains Kubernetes manifests for deploying Open WebUI with integrated MCP support through the mcpo (MCP-to-OpenAPI) proxy server.

## Components

- **Open WebUI**: Main web interface for interacting with LLMs
- **Ollama**: Local LLM backend
- **mcpo-proxy**: MCP-to-OpenAPI proxy server that bridges n8n MCP calendar server with Open WebUI

## Quick Start

### Prerequisites

- Kubernetes cluster
- ArgoCD installed (optional, but recommended)
- Docker Hub access to push the mcpo-proxy image

### Deployment

#### Option 1: Using ArgoCD (Recommended)

```bash
kubectl apply -f argocd-application.yaml
```

#### Option 2: Manual Deployment

1. Build and push the mcpo-proxy Docker image:
   ```bash
   cd mcpo-proxy
   ./build.sh
   ```

2. Deploy all components:
   ```bash
   kubectl apply -f webui-pvc.yaml
   kubectl apply -f ollama-statefulset.yaml
   kubectl apply -f ollama-service.yaml
   kubectl apply -f mcpo-proxy-deployment.yaml
   kubectl apply -f mcpo-proxy-service.yaml
   kubectl apply -f webui-deployment.yaml
   kubectl apply -f webui-service.yaml
   kubectl apply -f webui-ingress.yaml
   ```

## MCP Integration

The mcpo proxy server connects Open WebUI to your n8n MCP calendar server at `https://n8n.cluster.dphx.eu/mcp/my-calendar/sse`.

For detailed information about the MCP integration, see [MCPO_INTEGRATION.md](MCPO_INTEGRATION.md).

## Configuration

### Open WebUI

- **URL**: https://open-webui.cluster.dphx.eu
- **Ollama Backend**: http://ollama-service.applications.svc.cluster.local:11434
- **MCP Proxy**: http://mcpo-proxy-service.applications.svc.cluster.local:8000

### mcpo Proxy

The mcpo proxy is configured to connect to:
- **MCP Server**: https://n8n.cluster.dphx.eu/mcp/my-calendar/sse
- **API Documentation**: http://mcpo-proxy-service:8000/docs (when port-forwarded)

## File Structure

```
.
├── README.md                      # This file
├── MCPO_INTEGRATION.md           # Detailed MCP integration guide
├── argocd-application.yaml        # ArgoCD application manifest
├── mcpo-proxy/                    # MCP proxy Docker image
│   ├── Dockerfile                 # Docker image definition
│   ├── README.md                  # mcpo-proxy documentation
│   └── build.sh                   # Build and push script
├── mcpo-proxy-deployment.yaml     # mcpo-proxy Kubernetes deployment
├── mcpo-proxy-service.yaml        # mcpo-proxy Kubernetes service
├── webui-deployment.yaml          # Open WebUI deployment
├── webui-service.yaml             # Open WebUI service
├── webui-ingress.yaml             # Open WebUI ingress
├── webui-pvc.yaml                 # Open WebUI persistent volume claim
├── ollama-statefulset.yaml        # Ollama StatefulSet
└── ollama-service.yaml            # Ollama service
```

## Accessing the Services

### Open WebUI
- **External**: https://open-webui.cluster.dphx.eu
- **Internal**: http://open-webui-service.applications.svc.cluster.local:8080

### mcpo Proxy API Documentation
```bash
kubectl port-forward svc/mcpo-proxy-service 8000:8000
# Then visit: http://localhost:8000/docs
```

## Troubleshooting

See [MCPO_INTEGRATION.md](MCPO_INTEGRATION.md#troubleshooting) for detailed troubleshooting steps.

## License

This configuration is for the Open WebUI project. See the Open WebUI repository for license information.

# Quick Start Guide - MCP Integration

This is a quick reference for deploying Open WebUI with MCP integration.

## Prerequisites

✅ Kubernetes cluster running  
✅ `kubectl` configured and connected  
✅ Docker installed (for building the mcpo-proxy image)  
✅ Docker Hub access with `ineb01` account  

## 3-Step Deployment

### Step 1: Build the mcpo-proxy Docker Image

```bash
cd mcpo-proxy
./build.sh
```

When prompted, push the image to Docker Hub.

> **Note**: You must be logged in to Docker Hub as `ineb01`:
> ```bash
> docker login -u ineb01
> ```

### Step 2: Deploy to Kubernetes

Choose one of the following deployment methods:

#### Option A: Using the deployment script (Recommended)

```bash
./deploy.sh applications
```

#### Option B: Using ArgoCD

```bash
kubectl apply -f argocd-application.yaml
```

#### Option C: Using Kustomize

```bash
kubectl apply -k .
```

#### Option D: Manual deployment

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

### Step 3: Verify the Deployment

```bash
# Check all pods are running
kubectl get pods -n applications

# Check mcpo-proxy logs
kubectl logs -l app=mcpo-proxy -n applications

# Check Open WebUI logs
kubectl logs -l app=open-webui -n applications
```

## Accessing the Services

### Open WebUI
Open your browser and navigate to:
```
https://open-webui.cluster.dphx.eu
```

### mcpo API Documentation
To access the interactive API documentation:

```bash
kubectl port-forward svc/mcpo-proxy-service 8000:8000 -n applications
```

Then open: http://localhost:8000/docs

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│                                                              │
│  ┌────────────────┐      ┌──────────────────┐              │
│  │   Open WebUI   │─────▶│   mcpo-proxy     │              │
│  │   (Port 8080)  │      │   (Port 8000)    │──────────────┼─▶ n8n MCP Server
│  └────────────────┘      └──────────────────┘              │   (SSE endpoint)
│         │                                                    │
│         ▼                                                    │
│  ┌────────────────┐                                         │
│  │     Ollama     │                                         │
│  │  (Port 11434)  │                                         │
│  └────────────────┘                                         │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Details

### MCP Server Endpoint
- **URL**: https://n8n.cluster.dphx.eu/mcp/my-calendar/sse
- **Protocol**: SSE (Server-Sent Events)
- **Purpose**: Provides calendar-related MCP tools

### Environment Variables

The Open WebUI deployment includes:

```yaml
env:
- name: OLLAMA_BASE_URL
  value: "http://ollama-service.applications.svc.cluster.local:11434"
- name: OPENAI_API_BASE_URLS
  value: "http://mcpo-proxy-service.applications.svc.cluster.local:8000"
- name: OPENAI_API_KEYS
  value: "dummy-key"
```

## Troubleshooting

### mcpo-proxy not starting

Check the logs:
```bash
kubectl logs -l app=mcpo-proxy -n applications --tail=50
```

Verify the MCP server is accessible:
```bash
curl -v https://n8n.cluster.dphx.eu/mcp/my-calendar/sse
```

### Open WebUI can't connect to mcpo

Verify the service exists:
```bash
kubectl get svc mcpo-proxy-service -n applications
```

Test connectivity from within the cluster:
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n applications -- \
  curl http://mcpo-proxy-service:8000/docs
```

### Pods not starting

Check pod status:
```bash
kubectl get pods -n applications
kubectl describe pod <pod-name> -n applications
```

## Need More Help?

For detailed information, see:
- [MCPO_INTEGRATION.md](MCPO_INTEGRATION.md) - Comprehensive integration guide
- [README.md](README.md) - Full documentation

## Common Commands

```bash
# Watch deployment status
kubectl get pods -n applications -w

# View all resources
kubectl get all -n applications

# Delete deployment
kubectl delete -k . -n applications

# Restart mcpo-proxy
kubectl rollout restart deployment mcpo-proxy-deployment -n applications

# Restart Open WebUI
kubectl rollout restart deployment open-webui-deployment -n applications
```

## What's Next?

1. ✅ Verify all pods are running
2. ✅ Test the mcpo API at http://localhost:8000/docs (via port-forward)
3. ✅ Access Open WebUI at https://open-webui.cluster.dphx.eu
4. ✅ Try using MCP calendar tools in your conversations
5. ✅ Check the logs if anything isn't working as expected

Enjoy your MCP-integrated Open WebUI! 🎉

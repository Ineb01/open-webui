# MCP Proxy (mcpo) Integration Guide

This guide explains how to deploy and integrate the MCP-to-OpenAPI proxy server (mcpo) with your Open WebUI ArgoCD deployment.

## Overview

The MCP proxy server bridges your n8n MCP calendar server (https://n8n.cluster.dphx.eu/mcp/my-calendar/sse) with Open WebUI, exposing the MCP tools through standard REST/OpenAPI endpoints.

## Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│   Open WebUI    │────────▶│   mcpo-proxy     │────────▶│  n8n MCP Server │
│  (Port 8080)    │         │   (Port 8000)    │         │   (SSE)         │
└─────────────────┘         └──────────────────┘         └─────────────────┘
```

## Deployment Steps

### 1. Build and Push the Docker Image

Before deploying to Kubernetes, build the mcpo proxy Docker image:

```bash
cd mcpo-proxy
docker build -t ineb01/mcpo-proxy:latest .
docker push ineb01/mcpo-proxy:latest
```

**Important**: Make sure you're logged in to Docker Hub with the ineb01 account:
```bash
docker login -u ineb01
```

### 2. Deploy the mcpo Proxy to Kubernetes

Apply the mcpo proxy deployment and service:

```bash
kubectl apply -f mcpo-proxy-deployment.yaml
kubectl apply -f mcpo-proxy-service.yaml
```

Verify the deployment:

```bash
kubectl get pods -l app=mcpo-proxy
kubectl logs -l app=mcpo-proxy
```

### 3. Update Open WebUI Deployment

The Open WebUI deployment has been updated to include environment variables that configure it to use the mcpo proxy:

```bash
kubectl apply -f webui-deployment.yaml
```

The deployment now includes:
- `OPENAI_API_BASE_URLS`: Points to the mcpo proxy service
- `OPENAI_API_KEYS`: Dummy key for authentication (can be customized)

### 4. Verify the Integration

#### Check mcpo Proxy Status

```bash
# Port-forward to access the mcpo proxy locally
kubectl port-forward svc/mcpo-proxy-service 8000:8000

# Access the OpenAPI documentation
curl http://localhost:8000/docs
```

Or visit http://localhost:8000/docs in your browser to see the interactive API documentation.

#### Test the Integration

1. Access your Open WebUI at https://open-webui.cluster.dphx.eu
2. The MCP tools from your n8n calendar server should now be available
3. Try using calendar-related features that are exposed through the MCP server

## Configuration

### Environment Variables

The mcpo proxy deployment supports the following environment variables:

- `MCP_SERVER_URL`: The SSE endpoint of your n8n MCP server (default: https://n8n.cluster.dphx.eu/mcp/my-calendar/sse)

To change the MCP server URL, edit `mcpo-proxy-deployment.yaml`:

```yaml
env:
- name: MCP_SERVER_URL
  value: "https://your-server.example.com/mcp/endpoint"
```

### Resources

The default resource limits are:

- **Requests**: 250m CPU, 256Mi memory
- **Limits**: 500m CPU, 512Mi memory

Adjust these in `mcpo-proxy-deployment.yaml` based on your workload.

## Troubleshooting

### mcpo Proxy Won't Start

1. Check the logs:
   ```bash
   kubectl logs -l app=mcpo-proxy --tail=100
   ```

2. Verify the MCP server URL is accessible:
   ```bash
   kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
     curl -v https://n8n.cluster.dphx.eu/mcp/my-calendar/sse
   ```

### Open WebUI Can't Connect to mcpo

1. Verify the service is running:
   ```bash
   kubectl get svc mcpo-proxy-service
   ```

2. Test connectivity from a pod in the same namespace:
   ```bash
   kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
     curl http://mcpo-proxy-service.applications.svc.cluster.local:8000/docs
   ```

### Health Checks Failing

The deployment includes liveness and readiness probes that check the `/docs` endpoint. If these fail:

1. Increase `initialDelaySeconds` in the deployment
2. Check if the mcpo server is taking longer to start
3. Verify the n8n MCP server is accessible

## API Documentation

Once deployed, the mcpo proxy automatically generates OpenAPI documentation for all MCP tools. Access it at:

- **Internal**: http://mcpo-proxy-service.applications.svc.cluster.local:8000/docs
- **Port-forward**: `kubectl port-forward svc/mcpo-proxy-service 8000:8000` then visit http://localhost:8000/docs

## Updating the Deployment

### Rebuild Docker Image

After making changes to the Dockerfile:

```bash
cd mcpo-proxy
docker build -t ineb01/mcpo-proxy:latest .
docker push ineb01/mcpo-proxy:latest
```

### Rollout Updated Image

Force Kubernetes to pull the latest image:

```bash
kubectl rollout restart deployment mcpo-proxy-deployment
kubectl rollout status deployment mcpo-proxy-deployment
```

## Security Considerations

1. **API Keys**: The current setup uses a dummy API key. For production, consider:
   - Using Kubernetes secrets for API keys
   - Implementing proper authentication between Open WebUI and mcpo
   
2. **Network Policies**: Consider adding NetworkPolicies to restrict access to the mcpo proxy

3. **TLS**: The mcpo proxy communicates with the n8n server over HTTPS, ensuring encrypted communication

## Additional Resources

- [mcpo GitHub Repository](https://github.com/modelcontextprotocol/mcpo)
- [MCP Protocol Documentation](https://modelcontextprotocol.io)
- [Open WebUI Documentation](https://docs.openwebui.com)

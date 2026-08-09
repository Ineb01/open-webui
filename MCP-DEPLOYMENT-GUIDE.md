# MCP Proxy Deployment Guide

This guide provides detailed instructions for deploying and configuring the MCP-to-OpenAPI proxy server (mcpo) for your Open WebUI instance.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Steps](#deployment-steps)
4. [Configuration](#configuration)
5. [Integration with Open WebUI](#integration-with-open-webui)
6. [Customization](#customization)
7. [Troubleshooting](#troubleshooting)

## 🎯 Overview

The MCP (Model Context Protocol) proxy enables your Open WebUI instance to interact with MCP tool servers through standard REST/OpenAPI endpoints. This deployment connects to an existing MCP server at `https://n8n.cluster.dphx.eu/mcp/my-calendar/sse`.

### What Gets Deployed

- **mcpo-proxy-deployment**: Pod running the mcpo proxy server
- **mcpo-proxy-service**: Internal Kubernetes service for the proxy
- **mcpo-proxy-ingress**: External access via `mcpo-proxy.cluster.dphx.eu`

## ✅ Prerequisites

Before deploying, ensure you have:

- ✓ Kubernetes cluster access with `kubectl` configured
- ✓ `cert-manager` installed for TLS certificates
- ✓ DNS records pointing to your cluster ingress
- ✓ Access to the MCP server at `https://n8n.cluster.dphx.eu/mcp/my-calendar/sse`

## 🚀 Deployment Steps

### Step 1: Deploy the MCP Proxy

Apply all three Kubernetes manifests:

```bash
kubectl apply -f mcpo-proxy-deployment.yaml
kubectl apply -f mcpo-proxy-service.yaml
kubectl apply -f mcpo-proxy-ingress.yaml
```

### Step 2: Verify Deployment

Check that the pod is running:

```bash
kubectl get pods -l app=mcpo-proxy
```

Expected output:
```
NAME                                    READY   STATUS    RESTARTS   AGE
mcpo-proxy-deployment-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

Check the logs to ensure mcpo started successfully:

```bash
kubectl logs -l app=mcpo-proxy
```

You should see mcpo starting and connecting to the MCP server.

### Step 3: Verify Service

Check that the service is created:

```bash
kubectl get service mcpo-proxy-service
```

### Step 4: Verify Ingress

Check that the ingress is configured:

```bash
kubectl get ingress mcpo-proxy-ingress
```

Wait for the TLS certificate to be issued (this may take a few minutes).

### Step 5: Test the Proxy

Once the ingress is ready, access the API documentation:

```bash
curl https://mcpo-proxy.cluster.dphx.eu/docs
```

Or open `https://mcpo-proxy.cluster.dphx.eu/docs` in your browser to see the interactive Swagger UI.

## ⚙️ Configuration

### Environment Variables

The deployment uses the following environment variable:

- **MCP_SERVER_URL**: The URL of your MCP server
  - Default: `https://n8n.cluster.dphx.eu/mcp/my-calendar/sse`

### Resource Limits

Default resource allocation:

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

Adjust these based on your expected load and available cluster resources.

## 🤝 Integration with Open WebUI

### Option 1: Through Open WebUI UI

1. Access your Open WebUI instance at `https://open-webui.cluster.dphx.eu`
2. Log in with admin credentials
3. Navigate to **Settings** → **External Tools** or **Functions**
4. Add new OpenAPI tool:
   - **Name**: MCP Calendar Tools
   - **URL**: `https://mcpo-proxy.cluster.dphx.eu`
   - **Type**: OpenAPI
5. Save and the tools should now be available

### Option 2: Using Internal Service (for better performance)

If Open WebUI is in the same Kubernetes cluster, use the internal service URL:

- **Internal URL**: `http://mcpo-proxy-service.applications.svc.cluster.local:8000`

This avoids external network hops and provides better latency.

## 🎨 Customization

### Connecting to a Different MCP Server

To connect to a different MCP server:

1. Edit `mcpo-proxy-deployment.yaml`:
   ```yaml
   env:
   - name: MCP_SERVER_URL
     value: "https://your-mcp-server.example.com/mcp/endpoint/sse"
   ```

2. Reapply the deployment:
   ```bash
   kubectl apply -f mcpo-proxy-deployment.yaml
   ```

### Adding Authentication

To add API key authentication to the proxy:

1. Edit `mcpo-proxy-deployment.yaml`:
   ```yaml
   args:
     - |
       pip install --no-cache-dir mcpo mcp && \
       exec mcpo --host 0.0.0.0 --port 8000 --api-key "your-secret-key" --server-type sse -- $MCP_SERVER_URL
   ```

2. Store the API key as a Kubernetes secret (recommended):
   ```bash
   kubectl create secret generic mcpo-api-key --from-literal=api-key=your-secret-key
   ```

3. Update the deployment to use the secret:
   ```yaml
   env:
   - name: MCPO_API_KEY
     valueFrom:
       secretKeyRef:
         name: mcpo-api-key
         key: api-key
   args:
     - |
       pip install --no-cache-dir mcpo mcp && \
       exec mcpo --host 0.0.0.0 --port 8000 --api-key "$MCPO_API_KEY" --server-type sse -- $MCP_SERVER_URL
   ```

### Adding Custom Headers

If your MCP server requires authentication headers:

```yaml
args:
  - |
    pip install --no-cache-dir mcpo mcp && \
    exec mcpo --host 0.0.0.0 --port 8000 --server-type sse \
      --header '{"Authorization": "Bearer your-token"}' \
      -- $MCP_SERVER_URL
```

### Changing the Ingress Host

To use a different domain:

1. Edit `mcpo-proxy-ingress.yaml`:
   ```yaml
   tls:
   - hosts:
     - your-domain.example.com
     secretName: mcpo-proxy-tls
   rules:
   - host: your-domain.example.com
   ```

2. Ensure DNS records point to your cluster

3. Reapply: `kubectl apply -f mcpo-proxy-ingress.yaml`

### Using a Pre-built Docker Image

Instead of building on startup, you can use the provided Dockerfile:

1. Build the image:
   ```bash
   docker build -f Dockerfile.mcpo -t your-registry/mcpo-proxy:latest .
   ```

2. Push to your registry:
   ```bash
   docker push your-registry/mcpo-proxy:latest
   ```

3. Update `mcpo-proxy-deployment.yaml`:
   ```yaml
   containers:
   - name: mcpo-proxy
     image: your-registry/mcpo-proxy:latest
     # Remove command and args sections
   ```

## 🔧 Troubleshooting

### Proxy Not Starting

**Symptom**: Pod is in `CrashLoopBackOff` or `Error` state

**Solution**:
```bash
# Check pod logs
kubectl logs -l app=mcpo-proxy

# Common issues:
# 1. MCP server URL is unreachable
# 2. Python package installation failed
# 3. Invalid command syntax
```

### Cannot Connect to MCP Server

**Symptom**: Proxy starts but shows connection errors in logs

**Solution**:
```bash
# Test connectivity from within the cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -v https://n8n.cluster.dphx.eu/mcp/my-calendar/sse

# Check if MCP server is accessible and returning data
```

### TLS Certificate Not Issued

**Symptom**: HTTPS doesn't work, certificate warnings

**Solution**:
```bash
# Check cert-manager status
kubectl get certificate mcpo-proxy-tls

# Check certificate request
kubectl describe certificaterequest

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### API Documentation Not Loading

**Symptom**: 404 or timeout when accessing `/docs`

**Solution**:
```bash
# Check if ingress is working
kubectl describe ingress mcpo-proxy-ingress

# Test service directly (port-forward)
kubectl port-forward svc/mcpo-proxy-service 8000:8000

# Then access http://localhost:8000/docs
```

### Tools Not Appearing in Open WebUI

**Symptom**: MCP tools don't show up in Open WebUI

**Solution**:
1. Verify the proxy is accessible from Open WebUI
2. Check Open WebUI logs for connection errors
3. Ensure the OpenAPI schema is valid at `https://mcpo-proxy.cluster.dphx.eu/openapi.json`
4. Try refreshing the tools list in Open WebUI

### High Memory Usage

**Symptom**: Pod is being OOM killed

**Solution**:
Increase memory limits in `mcpo-proxy-deployment.yaml`:
```yaml
resources:
  limits:
    memory: "1Gi"
```

## 📊 Monitoring

### View Real-time Logs

```bash
kubectl logs -f -l app=mcpo-proxy
```

### Check Resource Usage

```bash
kubectl top pod -l app=mcpo-proxy
```

### Check Events

```bash
kubectl get events --sort-by='.lastTimestamp' | grep mcpo-proxy
```

## 🔄 Updates and Maintenance

### Update MCP Server URL

```bash
kubectl set env deployment/mcpo-proxy-deployment \
  MCP_SERVER_URL="https://new-server.example.com/mcp/sse"
```

### Restart the Proxy

```bash
kubectl rollout restart deployment/mcpo-proxy-deployment
```

### Scale the Deployment

```bash
kubectl scale deployment/mcpo-proxy-deployment --replicas=3
```

## 📚 Additional Resources

- [MCP Specification](https://modelcontextprotocol.io/)
- [mcpo GitHub](https://github.com/open-webui/mcpo)
- [Open WebUI Documentation](https://docs.openwebui.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 💬 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review pod logs for error messages
3. Verify your MCP server is accessible and working
4. Open an issue in the repository with logs and configuration

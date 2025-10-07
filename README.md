# open-webui

## 🛰️ MCP (Model Context Protocol) Support

This repository provides Kubernetes deployment configurations for Open WebUI with integrated MCP-to-OpenAPI proxy server (mcpo) support.

### 📌 What is the MCP Proxy Server?

The MCP-to-OpenAPI proxy server allows you to use tool servers implemented with MCP (Model Context Protocol) directly via standard REST/OpenAPI APIs. This deployment includes configurations to proxy an existing MCP server running at `https://n8n.cluster.dphx.eu/mcp/my-calendar/sse`.

### 🚀 Quick Start

Deploy all components to your Kubernetes cluster:

```bash
# Deploy Open WebUI
kubectl apply -f webui-pvc.yaml
kubectl apply -f webui-deployment.yaml
kubectl apply -f webui-service.yaml
kubectl apply -f webui-ingress.yaml

# Deploy Ollama (optional)
kubectl apply -f ollama-statefulset.yaml
kubectl apply -f ollama-service.yaml

# Deploy MCP Proxy
kubectl apply -f mcpo-proxy-deployment.yaml
kubectl apply -f mcpo-proxy-service.yaml
kubectl apply -f mcpo-proxy-ingress.yaml
```

### 🔧 MCP Proxy Configuration

The mcpo proxy is configured to connect to an SSE-based MCP server at:
- **MCP Server URL**: `https://n8n.cluster.dphx.eu/mcp/my-calendar/sse`
- **Proxy Port**: `8000`
- **Ingress Host**: `mcpo-proxy.cluster.dphx.eu`

#### Accessing the MCP Proxy

Once deployed, the MCP proxy will be available at:
- **API Documentation**: `https://mcpo-proxy.cluster.dphx.eu/docs`
- **API Base URL**: `https://mcpo-proxy.cluster.dphx.eu`

#### Customizing the MCP Server URL

To connect to a different MCP server, edit `mcpo-proxy-deployment.yaml` and change the `MCP_SERVER_URL` environment variable:

```yaml
env:
- name: MCP_SERVER_URL
  value: "https://your-mcp-server.example.com/mcp/endpoint/sse"
```

### 💡 Why Use mcpo?

MCP tool servers typically communicate via standard input/output (stdio), which works great locally but presents challenges when:
- Deploying your interface (like Open WebUI) in the cloud
- The MCP server runs on a different machine
- You need standard REST API endpoints

The mcpo proxy solves these problems by:

✅ **Instant Compatibility**: Works with existing OpenAPI tools, SDKs, and clients  
🛡 **Secure & Scalable**: Provides standard HTTP endpoints with authentication support  
🧠 **Auto-Generated Documentation**: Interactive OpenAPI/Swagger UI at `/docs`  
🔌 **Simple HTTP**: No complex socket setup or platform-specific code

### 🌐 Integration with Open WebUI

After deploying the mcpo proxy, integrate it with Open WebUI:

1. Access Open WebUI at `https://open-webui.cluster.dphx.eu`
2. Navigate to Settings → External Tools
3. Add the MCP proxy endpoint: `https://mcpo-proxy.cluster.dphx.eu`
4. The MCP tools will now be available within Open WebUI

### 📖 Architecture

```
┌─────────────────┐
│   Open WebUI    │
│ (Port 8080)     │
└────────┬────────┘
         │
         │ HTTP/REST
         │
┌────────▼────────┐
│   mcpo Proxy    │
│ (Port 8000)     │
└────────┬────────┘
         │
         │ SSE
         │
┌────────▼────────┐
│   MCP Server    │
│  (n8n.cluster)  │
└─────────────────┘
```

### 🔒 Security Considerations

- The mcpo proxy supports API key authentication via `--api-key` flag
- TLS certificates are automatically provisioned via cert-manager
- For production use, consider adding authentication headers in the deployment

### 📚 Additional Resources

- [MCP Documentation](https://modelcontextprotocol.io/)
- [mcpo GitHub Repository](https://github.com/open-webui/mcpo)
- [Open WebUI Documentation](https://docs.openwebui.com/)

### 🛠️ Troubleshooting

**Proxy not connecting to MCP server:**
- Verify the MCP_SERVER_URL is accessible from within the cluster
- Check pod logs: `kubectl logs -l app=mcpo-proxy`

**API documentation not loading:**
- Ensure the ingress is properly configured
- Verify DNS records point to your cluster

**Tools not appearing in Open WebUI:**
- Confirm the mcpo proxy is running: `kubectl get pods -l app=mcpo-proxy`
- Check that Open WebUI can reach the proxy service

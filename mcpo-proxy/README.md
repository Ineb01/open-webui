# MCP Proxy Server for Open WebUI

This directory contains the Dockerfile for building the mcpo (MCP-to-OpenAPI) proxy server that connects Open WebUI to the n8n MCP calendar server.

## What is mcpo?

mcpo is an MCP (Model Context Protocol) to OpenAPI proxy server that exposes MCP tool servers through standard REST/OpenAPI endpoints. This makes it easy to integrate MCP-based tools with Open WebUI running in the cloud.

## Building the Docker Image

To build the Docker image for the mcpo proxy:

```bash
docker build -t ineb01/mcpo-proxy:latest .
docker push ineb01/mcpo-proxy:latest
```

## Configuration

The proxy is configured to connect to the n8n MCP calendar server at:
- **MCP Server URL**: https://n8n.cluster.dphx.eu/mcp/my-calendar/sse

The proxy exposes the MCP tools via REST API on port 8000.

## API Documentation

Once deployed, the OpenAPI documentation is available at:
- `http://<mcpo-service>:8000/docs`

## Integration with Open WebUI

The Open WebUI deployment is configured to communicate with this mcpo proxy through the `mcpo-proxy-service` Kubernetes service. The proxy translates MCP tool calls into standard REST API calls that Open WebUI can easily consume.

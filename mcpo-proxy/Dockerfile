FROM python:3.11-slim

WORKDIR /app

# Install mcpo and mcp-client-sse for SSE support
RUN pip install --no-cache-dir mcpo mcp-client-sse

# Expose port 8000 for the proxy server
EXPOSE 8000

# Use mcpo to proxy the n8n MCP server via SSE
# The MCP_SERVER_URL environment variable will be used to configure the target
ENV MCP_SERVER_URL=https://n8n.cluster.dphx.eu/mcp/my-calendar/sse

# Start mcpo with the SSE client pointing to the n8n MCP server
CMD uvx mcpo --host 0.0.0.0 --port 8000 -- mcp-client-sse ${MCP_SERVER_URL}

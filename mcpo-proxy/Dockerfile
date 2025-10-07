FROM python:3.11-slim

WORKDIR /app

# Install uv for faster package management and mcpo
RUN pip install --no-cache-dir uv && \
    uv pip install --system mcpo

# Expose port 8000 for the proxy server
EXPOSE 8000

# Use mcpo to proxy the n8n MCP server via SSE
# The MCP_SERVER_URL environment variable will be used to configure the target
ENV MCP_SERVER_URL=https://n8n.cluster.dphx.eu/mcp/my-calendar/sse

# Start mcpo with the SSE client pointing to the n8n MCP server
# Using uvx to run mcp-client-sse which will connect to the SSE endpoint
CMD ["sh", "-c", "uvx mcpo --host 0.0.0.0 --port 8000 -- uvx mcp-client-sse ${MCP_SERVER_URL}"]

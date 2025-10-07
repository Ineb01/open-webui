#!/bin/bash
# Quick deployment script for MCP Proxy

set -e

echo "🚀 Deploying MCP Proxy to Kubernetes cluster..."
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connection
echo "📋 Checking cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Cannot connect to Kubernetes cluster"
    echo "   Please ensure kubectl is configured correctly"
    exit 1
fi
echo "✅ Connected to cluster"
echo ""

# Deploy MCP Proxy components
echo "📦 Deploying MCP Proxy components..."
echo ""

echo "  → Applying mcpo-proxy-deployment.yaml..."
kubectl apply -f mcpo-proxy-deployment.yaml

echo "  → Applying mcpo-proxy-service.yaml..."
kubectl apply -f mcpo-proxy-service.yaml

echo "  → Applying mcpo-proxy-ingress.yaml..."
kubectl apply -f mcpo-proxy-ingress.yaml

echo ""
echo "✅ MCP Proxy deployed successfully!"
echo ""

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/mcpo-proxy-deployment 2>/dev/null || {
    echo "⚠️  Deployment is taking longer than expected"
    echo "   You can check status with: kubectl get pods -l app=mcpo-proxy"
}

echo ""
echo "📊 Current status:"
kubectl get pods -l app=mcpo-proxy
echo ""

echo "🎉 Deployment complete!"
echo ""
echo "📖 Access the API documentation at:"
echo "   https://mcpo-proxy.cluster.dphx.eu/docs"
echo ""
echo "🔍 Check logs with:"
echo "   kubectl logs -l app=mcpo-proxy"
echo ""
echo "📚 For more information, see MCP-DEPLOYMENT-GUIDE.md"

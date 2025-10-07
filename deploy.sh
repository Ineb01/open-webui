#!/bin/bash

# Deployment script for Open WebUI with MCP integration
# This script deploys all components in the correct order

set -e

echo "======================================"
echo "Open WebUI with MCP Deployment Script"
echo "======================================"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Optional: Set namespace
NAMESPACE=${1:-applications}
echo "Using namespace: ${NAMESPACE}"
echo ""

# Create namespace if it doesn't exist
echo "Creating namespace (if not exists)..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Deploying components..."
echo ""

# Deploy Ollama
echo "[1/8] Deploying Ollama StatefulSet..."
kubectl apply -f ollama-statefulset.yaml -n ${NAMESPACE}

echo "[2/8] Deploying Ollama Service..."
kubectl apply -f ollama-service.yaml -n ${NAMESPACE}

# Deploy MCP Proxy
echo "[3/8] Deploying mcpo-proxy..."
kubectl apply -f mcpo-proxy-deployment.yaml -n ${NAMESPACE}

echo "[4/8] Deploying mcpo-proxy Service..."
kubectl apply -f mcpo-proxy-service.yaml -n ${NAMESPACE}

# Deploy Open WebUI
echo "[5/8] Deploying Open WebUI PVC..."
kubectl apply -f webui-pvc.yaml -n ${NAMESPACE}

echo "[6/8] Deploying Open WebUI..."
kubectl apply -f webui-deployment.yaml -n ${NAMESPACE}

echo "[7/8] Deploying Open WebUI Service..."
kubectl apply -f webui-service.yaml -n ${NAMESPACE}

echo "[8/8] Deploying Open WebUI Ingress..."
kubectl apply -f webui-ingress.yaml -n ${NAMESPACE}

echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "Checking deployment status..."
echo ""

# Wait a moment for resources to be created
sleep 2

echo "Deployments:"
kubectl get deployments -n ${NAMESPACE}
echo ""

echo "Services:"
kubectl get services -n ${NAMESPACE}
echo ""

echo "Pods:"
kubectl get pods -n ${NAMESPACE}
echo ""

echo "======================================"
echo "Next Steps:"
echo "======================================"
echo ""
echo "1. Wait for all pods to be in 'Running' state:"
echo "   kubectl get pods -n ${NAMESPACE} -w"
echo ""
echo "2. Check mcpo-proxy logs:"
echo "   kubectl logs -l app=mcpo-proxy -n ${NAMESPACE}"
echo ""
echo "3. Check Open WebUI logs:"
echo "   kubectl logs -l app=open-webui -n ${NAMESPACE}"
echo ""
echo "4. Access mcpo API documentation (via port-forward):"
echo "   kubectl port-forward svc/mcpo-proxy-service 8000:8000 -n ${NAMESPACE}"
echo "   Then visit: http://localhost:8000/docs"
echo ""
echo "5. Access Open WebUI at:"
echo "   https://open-webui.cluster.dphx.eu"
echo ""

#!/bin/bash

# Build and push script for mcpo-proxy Docker image
# Usage: ./build.sh [tag]
# Default tag: latest

set -e

TAG=${1:-latest}
IMAGE_NAME="ineb01/mcpo-proxy"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

echo "Building Docker image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .

echo ""
echo "Image built successfully!"
echo ""
echo "To push the image to Docker Hub, run:"
echo "  docker push ${FULL_IMAGE}"
echo ""
echo "Or push now by running:"
read -p "Push image now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Pushing image to Docker Hub..."
    docker push "${FULL_IMAGE}"
    echo "Image pushed successfully!"
else
    echo "Skipping push. You can push later with:"
    echo "  docker push ${FULL_IMAGE}"
fi

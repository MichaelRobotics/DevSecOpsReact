#!/bin/bash
set -e

# Script to test Docker Hub login using credentials from Kubernetes secret
# Usage: ./test-dockerhub-login.sh

# Error handling
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

# Check for kubectl
if ! command -v kubectl &> /dev/null; then
  error_exit "kubectl is not installed. Please install kubectl first."
fi

# Check if connected to a Kubernetes cluster
if ! kubectl get nodes &> /dev/null; then
  error_exit "Not connected to a Kubernetes cluster. Please check your kubeconfig."
fi

# Check for docker
if ! command -v docker &> /dev/null; then
  error_exit "docker is not installed. Please install docker first."
fi

# Variables
NAMESPACE="default"
SECRET_NAME="dockerhub-credentials"

# Check if the secret exists
if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
  error_exit "Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'. Run create-dockerhub-secret.sh first."
fi

echo "=== Docker Hub Login Test ==="
echo "Using secret: $SECRET_NAME"

# Extract Docker Hub credentials from the secret
echo "Extracting credentials from Kubernetes secret..."
SECRET_DATA=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o json)
DOCKER_CONFIG=$(echo "$SECRET_DATA" | jq -r '.data.".dockerconfigjson"' | base64 -d)

if [ -z "$DOCKER_CONFIG" ]; then
  error_exit "Failed to extract Docker configuration from secret."
fi

DOCKERHUB_SERVER=$(echo "$DOCKER_CONFIG" | jq -r '.auths | keys[0]')
DOCKERHUB_USERNAME=$(echo "$DOCKER_CONFIG" | jq -r --arg server "$DOCKERHUB_SERVER" '.auths[$server].username')
DOCKERHUB_PASSWORD=$(echo "$DOCKER_CONFIG" | jq -r --arg server "$DOCKERHUB_SERVER" '.auths[$server].password')

if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_PASSWORD" ]; then
  error_exit "Failed to extract username or password from Docker configuration."
fi

echo "Successfully extracted credentials for user: $DOCKERHUB_USERNAME"

# Test Docker Hub login
echo "Testing Docker Hub login..."
echo "$DOCKERHUB_PASSWORD" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin

if [ $? -ne 0 ]; then
  error_exit "Docker Hub login failed. Check your credentials."
fi

echo "✅ Successfully logged in to Docker Hub as $DOCKERHUB_USERNAME"

# Try to pull a private image if available
echo "Testing access to your Docker Hub repositories..."
IMAGE_NAME="$DOCKERHUB_USERNAME/clusterimages:latest-otel-demo-currency"

echo "Attempting to pull: $IMAGE_NAME"
if docker pull "$IMAGE_NAME"; then
  echo "✅ Successfully pulled image: $IMAGE_NAME"
  
  # Clean up pulled image
  docker rmi "$IMAGE_NAME" &>/dev/null || true
  echo "Image removed from local cache."
else
  echo "⚠️ Couldn't pull the specific image: $IMAGE_NAME"
  echo "This could be due to the image not existing or another issue."
  echo "However, we've verified that login was successful."
fi

# Logout for cleanup
docker logout
echo "Logged out from Docker Hub."

echo ""
echo "=== Test Results ==="
echo "✅ Docker Hub login test passed!"
echo "The Kubernetes secret '$SECRET_NAME' contains valid Docker Hub credentials."
echo "Your deployments can now pull images from your private Docker Hub repositories." 
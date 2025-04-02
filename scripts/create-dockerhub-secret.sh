#!/bin/bash
set -e

# Script to create Kubernetes secret for DockerHub authentication
# Usage: 
# - Interactive: ./create-dockerhub-secret.sh <your-dockerhub-pat>
# - CI/CD: export DOCKERHUB_USERNAME=username && export DOCKERHUB_TOKEN=token && ./create-dockerhub-secret.sh

# Error handling
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

# Check for kubernetes CLI
if ! command -v kubectl &> /dev/null; then
  error_exit "kubectl is not installed. Please install kubectl first."
fi

# Check if connected to a Kubernetes cluster
if ! kubectl get nodes &> /dev/null; then
  error_exit "Not connected to a Kubernetes cluster. Please check your kubeconfig."
fi

# DockerHub credentials
# Priority: Environment variables > Command-line arguments > Interactive prompt
if [ -n "$DOCKERHUB_USERNAME" ]; then
  # Using environment variable
  echo "Using DockerHub username from environment variable"
else
  # Default value
  DOCKERHUB_USERNAME="robclusterdev"
fi

# Default email (can be updated)
DOCKERHUB_EMAIL="admin@example.com"

# Get PAT from environment variable, command line argument, or prompt for it
if [ -n "$DOCKERHUB_TOKEN" ]; then
  # Using environment variable
  DOCKERHUB_PAT="$DOCKERHUB_TOKEN"
  echo "Using DockerHub token from environment variable"
elif [ $# -eq 0 ]; then
  echo "Please enter your DockerHub Personal Access Token:"
  read -s DOCKERHUB_PAT
  echo
  if [ -z "$DOCKERHUB_PAT" ]; then
    error_exit "PAT cannot be empty"
  fi
else
  DOCKERHUB_PAT="$1"
fi

# Set Kubernetes namespace and secret name
NAMESPACE="default"
SECRET_NAME="dockerhub-credentials"

# Create the secret
echo "Creating Kubernetes secret for DockerHub authentication..."
kubectl create secret docker-registry "$SECRET_NAME" \
  --docker-server="https://index.docker.io/v1/" \
  --docker-username="$DOCKERHUB_USERNAME" \
  --docker-password="$DOCKERHUB_PAT" \
  --docker-email="$DOCKERHUB_EMAIL" \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

# Verify secret was created
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
  echo "✅ DockerHub secret '$SECRET_NAME' created successfully in namespace '$NAMESPACE'"
  echo ""
  echo "To use this secret in your deployments, add or update the imagePullSecrets section:"
  echo ""
  echo "spec:"
  echo "  imagePullSecrets:"
  echo "  - name: $SECRET_NAME"
  echo ""
  echo "For existing deployments, you can patch them with:"
  echo "kubectl patch deployment <deployment-name> -p '{\"spec\":{\"template\":{\"spec\":{\"imagePullSecrets\":[{\"name\":\"$SECRET_NAME\"}]}}}}'"
else
  error_exit "Failed to create DockerHub secret"
fi

# Success
echo "Done! Your deployments can now pull images from DockerHub using your PAT." 
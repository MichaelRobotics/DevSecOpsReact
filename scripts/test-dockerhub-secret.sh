#!/bin/bash
set -e

# Script to test DockerHub secret by creating a test pod
# Usage: ./test-dockerhub-secret.sh

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

# Variables
NAMESPACE="default"
SECRET_NAME="dockerhub-credentials"
POD_NAME="dockerhub-test-pod"
DOCKERHUB_USERNAME="robclusterdev"

# Check if the secret exists
if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
  error_exit "Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'. Run create-dockerhub-secret.sh first."
fi

echo "Testing DockerHub login using secret '$SECRET_NAME'..."

# Cleanup any previous test pod
kubectl delete pod "$POD_NAME" -n "$NAMESPACE" --ignore-not-found=true

# Create a test pod that uses the secret
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: $NAMESPACE
spec:
  containers:
  - name: test-container
    image: robclusterdev/clusterimages:latest-otel-demo-currency
    imagePullPolicy: Always
    command: ["sh", "-c", "echo 'Image pulled successfully!' && sleep 10"]
  imagePullSecrets:
  - name: $SECRET_NAME
  restartPolicy: Never
EOF

echo "Created test pod to verify DockerHub authentication..."
echo "Waiting for pod to start (this may take a few seconds)..."

# Wait for the pod to start or fail
timeout=60  # seconds
start_time=$(date +%s)
while true; do
  POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")
  
  if [[ "$POD_STATUS" == "Running" ]]; then
    echo -e "\n✅ SUCCESS: Pod is running, which means authentication was successful!"
    break
  elif [[ "$POD_STATUS" == "Failed" || "$POD_STATUS" == "Error" ]]; then
    echo -e "\n❌ FAILURE: Pod failed to start."
    echo "Checking pod events for more details:"
    kubectl describe pod "$POD_NAME" -n "$NAMESPACE" | grep -A 10 "Events:"
    kubectl delete pod "$POD_NAME" -n "$NAMESPACE" --ignore-not-found=true
    error_exit "DockerHub authentication test failed. Check your PAT and try again."
    break
  fi
  
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  
  if [ $elapsed -ge $timeout ]; then
    echo -e "\n⚠️ TIMEOUT: Pod didn't reach Running state within $timeout seconds."
    kubectl describe pod "$POD_NAME" -n "$NAMESPACE" | grep -A 10 "Events:"
    kubectl delete pod "$POD_NAME" -n "$NAMESPACE" --ignore-not-found=true
    error_exit "Test timed out. This might indicate network issues or authentication problems."
    break
  fi
  
  echo -n "."
  sleep 2
done

# Get pod logs if successful
if [[ "$POD_STATUS" == "Running" ]]; then
  echo "Pod output:"
  kubectl logs "$POD_NAME" -n "$NAMESPACE"
fi

# Cleanup
echo "Cleaning up test pod..."
kubectl delete pod "$POD_NAME" -n "$NAMESPACE" --ignore-not-found=true

echo -e "\nTest completed. Secret appears to be working correctly!"
echo "Your Kubernetes deployments should be able to pull images from DockerHub using this secret." 
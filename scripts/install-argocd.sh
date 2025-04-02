#!/bin/bash
set -e

echo "=== Installing ArgoCD ==="

# Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Step 1: Apply our custom ArgoCD infrastructure components
echo "Applying ArgoCD custom installation manifest..."
kubectl apply -f kubernetes/argocd/install.yaml

# Step 2: Apply the official ArgoCD components that aren't in our custom manifest
echo "Applying additional ArgoCD components..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -l app.kubernetes.io/component=application-controller
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -l app.kubernetes.io/component=repo-server
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -l app.kubernetes.io/component=dex-server

# Step 3: Delete the default service and use our custom one with proper ports
echo "Applying custom ArgoCD server service..."
kubectl delete -n argocd service argocd-server --ignore-not-found
# Apply the service directly from our install.yaml
kubectl apply -f kubernetes/argocd/install.yaml -n argocd

# Wait for ArgoCD server to become ready
echo "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the ArgoCD admin password
echo "ArgoCD is installed!"
echo "ArgoCD admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

# Step 4: Apply our Application definition separately (following best practices)
echo "Applying ArgoCD Application CR for React app..."
kubectl apply -f kubernetes/argocd/application.yaml

# Get LoadBalancer URL for ArgoCD
echo "Waiting for LoadBalancer IP address..."
sleep 30  # Give AWS time to provision the LoadBalancer
ARGOCD_LB=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "=== ArgoCD Installation Complete ==="
echo ""
echo "Access the ArgoCD UI at: https://$ARGOCD_LB:8443"
echo ""
echo "If the LoadBalancer URL is not available yet, you can still use port-forwarding:"
echo "kubectl port-forward svc/argocd-server -n argocd 9090:8443"
echo "Then visit: https://localhost:9090" 
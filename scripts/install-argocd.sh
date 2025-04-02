#!/bin/bash
set -e

echo "=== Installing ArgoCD ==="

# Clean up previous setup
kubectl delete namespace argocd --ignore-not-found

# Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Step 1: Apply custom manifest (server only)
echo "Applying custom ArgoCD installation manifest..."
kubectl apply -f kubernetes/argocd/install.yaml -n argocd

# Step 2: Apply remaining official components (excluding server and dex)
echo "Applying remaining ArgoCD components..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --selector 'app.kubernetes.io/component notin (server,dex-server)'

# Wait for ArgoCD server
echo "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Update ArgoCD URL (HTTP, no TLS)
echo "Updating ArgoCD URL..."
ARGOCD_LB=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
kubectl patch configmap argocd-cm -n argocd --type merge -p "{\"data\":{\"url\":\"http://$ARGOCD_LB:8080\"}}"

# Get admin password
echo "ArgoCD admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

# Apply Application
echo "Applying ArgoCD Application CR for React app..."
kubectl apply -f kubernetes/argocd/application.yaml

echo "=== ArgoCD Installation Complete ==="
echo "Access the ArgoCD UI at: http://$ARGOCD_LB:8080"
echo "Or use port-forwarding: kubectl port-forward svc/argocd-server -n argocd 9090:8080"
echo "Then visit: http://localhost:9090"
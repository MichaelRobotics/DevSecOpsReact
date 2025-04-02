#!/bin/bash
set -e

echo "=== Installing ArgoCD ==="

# Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Step 1: Apply custom manifest first
echo "Applying custom ArgoCD installation manifest..."
kubectl apply -f kubernetes/argocd/install.yaml -n argocd

# Step 2: Apply remaining official components
echo "Applying remaining ArgoCD components..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --selector 'app.kubernetes.io/component notin (server)'

# Wait for ArgoCD server to become ready
echo "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Update ArgoCD URL
echo "Updating ArgoCD URL..."
ARGOCD_LB=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
kubectl patch configmap argocd-cm -n argocd --type merge -p "{\"data\":{\"url\":\"https://$ARGOCD_LB:8443\"}}"

# Get the ArgoCD admin password
echo "ArgoCD is installed!"
echo "ArgoCD admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

# Step 3: Apply the Application definition
echo "Applying ArgoCD Application CR for React app..."
kubectl apply -f kubernetes/argocd/application.yaml

# Get LoadBalancer URL for ArgoCD
echo "=== ArgoCD Installation Complete ==="
echo "Access the ArgoCD UI at: https://$ARGOCD_LB:8443"
echo "If the LoadBalancer URL is not available yet, use port-forwarding:"
echo "kubectl port-forward svc/argocd-server -n argocd 9090:8443"
echo "Then visit: https://localhost:9090"
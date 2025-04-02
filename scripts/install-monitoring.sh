#!/bin/bash
set -e

echo "=== Installing Prometheus and Grafana ==="

# Add the Prometheus community Helm repository
echo "Adding Prometheus community Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
echo "Installing kube-prometheus-stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.service.type=LoadBalancer \
  --set prometheus.service.type=LoadBalancer

# Wait for Prometheus and Grafana to be ready
echo "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-kube-prometheus-operator -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-grafana -n monitoring

# Get Grafana admin password
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d)

# Get LoadBalancer IPs
echo "Waiting for LoadBalancer IP addresses..."
sleep 30  # Give AWS time to provision the LoadBalancers
GRAFANA_LB=$(kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
PROMETHEUS_LB=$(kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "=== Monitoring Installation Complete ==="
echo ""
echo "Grafana credentials:"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"
echo ""
echo "Access Grafana at: http://$GRAFANA_LB"
echo "Access Prometheus at: http://$PROMETHEUS_LB:9090"
echo ""
echo "If LoadBalancer URLs are not available yet, you can still use port-forwarding:"
echo "kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
echo "kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090" 
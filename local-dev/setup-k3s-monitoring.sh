#!/bin/bash
set -e

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up K3s cluster with Prometheus and Grafana for local development...${NC}"

# Check if K3s is already installed
if ! command -v k3s &> /dev/null; then
    echo -e "${YELLOW}Installing K3s...${NC}"
    curl -sfL https://get.k3s.io | sh -
    # Wait for K3s to start
    sleep 10
    # Make kubectl available for the current user
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
    export KUBECONFIG=~/.kube/config
    
    # Create a symlink to kubectl for convenience if it doesn't exist
    if ! command -v kubectl &> /dev/null; then
        echo -e "${YELLOW}Creating kubectl symlink...${NC}"
        sudo ln -sf $(which k3s) /usr/local/bin/kubectl
    fi
else
    echo -e "${GREEN}K3s is already installed.${NC}"
fi

# Wait for nodes to be ready
echo -e "${YELLOW}Waiting for nodes to be ready...${NC}"
kubectl wait --for=condition=ready node --all --timeout=60s

# Install Helm if not present
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}Installing Helm...${NC}"
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
else
    echo -e "${GREEN}Helm is already installed.${NC}"
fi

# Add the Prometheus community Helm repository
echo -e "${YELLOW}Adding Prometheus Helm repository...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo -e "${YELLOW}Creating monitoring namespace...${NC}"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack (includes Prometheus, Grafana, AlertManager)
echo -e "${YELLOW}Installing Prometheus and Grafana...${NC}"
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.service.type=NodePort \
  --set grafana.service.type=NodePort \
  --values - <<EOF
grafana:
  adminPassword: admin
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      kubernetes-app:
        json: |
          $(cat kubernetes/monitoring/base/react-app-dashboard.yaml | sed 's/^/          /')
        datasource: Prometheus
      common-dashboard:
        json: |
          $(cat kubernetes/monitoring/base/common-dashboard.yaml | sed 's/^/          /')
        datasource: Prometheus
EOF

# Wait for deployments to be ready
echo -e "${YELLOW}Waiting for Prometheus and Grafana to be ready...${NC}"
kubectl -n monitoring wait --for=condition=available --timeout=300s deployment/monitoring-grafana
kubectl -n monitoring wait --for=condition=available --timeout=300s deployment/monitoring-kube-prometheus-server

# Get NodePort for Prometheus and Grafana
PROMETHEUS_PORT=$(kubectl get svc -n monitoring monitoring-kube-prometheus-server -o jsonpath='{.spec.ports[0].nodePort}')
GRAFANA_PORT=$(kubectl get svc -n monitoring monitoring-grafana -o jsonpath='{.spec.ports[0].nodePort}')

echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo -e "${GREEN}Prometheus URL: http://localhost:$PROMETHEUS_PORT${NC}"
echo -e "${GREEN}Grafana URL: http://localhost:$GRAFANA_PORT${NC}"
echo -e "${GREEN}Grafana Default Credentials: admin / admin${NC}"

# Create script to setup port-forwarding for local access
cat > local-dev/port-forward.sh << 'EOF'
#!/bin/bash
# Quick port-forward script for local development
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up port forwarding for monitoring services...${NC}"
echo "Prometheus will be available at http://localhost:9090"
echo "Grafana will be available at http://localhost:3000"
echo "Press Ctrl+C to stop"

# Run port-forwarding in background
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-server 9090:9090 &
prom_pid=$!
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80 &
grafana_pid=$!

# Trap Ctrl+C and kill background processes
trap 'kill $prom_pid $grafana_pid; exit' INT TERM
wait
EOF

chmod +x local-dev/port-forward.sh

echo -e "${YELLOW}A port-forwarding script has been created at local-dev/port-forward.sh${NC}" 
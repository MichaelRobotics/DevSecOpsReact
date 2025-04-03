# Local Development Tools

This directory contains scripts to help set up and manage a local Kubernetes development environment.

## Available Scripts

### 1. Set up K3s with Prometheus and Grafana

To set up a local K3s cluster with monitoring tools:

```bash
./setup-k3s-monitoring.sh
```

This will:
- Install K3s if not already installed
- Set up Helm
- Deploy Prometheus and Grafana using the kube-prometheus-stack
- Configure dashboards from the kubernetes/monitoring/base directory

### 2. Deploy the Application with Kustomize

To deploy all resources defined in the kubernetes directory:

```bash
./kustomize-deploy.sh [namespace]
```

This will apply all resources from the kubernetes directory's kustomization.yaml file into the specified namespace (defaults to 'app').

### 3. Port Forwarding for Monitoring Tools

If you need to access Prometheus and Grafana through stable port numbers:

```bash
./port-forward.sh
```

This script will set up:
- Prometheus on http://localhost:9090
- Grafana on http://localhost:3000 (default login: admin/admin)

## Manual Deployment with Kustomize

If you prefer to use kubectl directly:

```bash
# Deploy everything in the kubernetes directory
kubectl apply -k kubernetes/ -n app

# View the resources that would be applied without actually applying them
kubectl kustomize kubernetes/

# Delete all resources
kubectl delete -k kubernetes/ -n app
``` 
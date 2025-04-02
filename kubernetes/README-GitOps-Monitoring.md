# GitOps and Monitoring Setup on EKS

This document provides instructions for setting up GitOps with ArgoCD and monitoring with Prometheus and Grafana for the DevSecOpsReact application running on AWS EKS.

## AWS EKS Integration

The entire platform is deployed to an AWS Elastic Kubernetes Service (EKS) cluster, which provides a managed Kubernetes service that makes it easier to run Kubernetes on AWS.

### EKS Prerequisites

Before running the platform deployment, ensure you have:

1. An EKS cluster created via the Infrastructure Deployment pipeline
2. Proper AWS IAM permissions to interact with the EKS cluster
3. AWS credentials configured in GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

## Platform Deployment Pipeline

A dedicated CI/CD pipeline has been created for deploying the platform components (ArgoCD, Prometheus, and Grafana). This pipeline is defined in `.github/workflows/platform-deployment.yml` and is triggered by:

1. Changes to platform-related files in the repository
2. Manual triggering via GitHub Actions workflow_dispatch (with options to specify cluster name and region)

The pipeline uses the following default values:
- Cluster Name: `DevSecOpsReact`
- AWS Region: `us-west-2`

The pipeline deploys:
- Docker Hub Secret for image pulling
- ArgoCD for GitOps-based deployments
- Prometheus for metrics collection
- Grafana for metrics visualization
- Custom service monitors and dashboards

### Security Components

The platform pipeline manages the following security components:

1. **Docker Hub Secret (`dockerhub-credentials`)**:
   - Creates a Kubernetes secret for authenticating with Docker Hub
   - Used by deployments to pull private images
   - Automatically configured with the credentials from GitHub Secrets

## GitOps with ArgoCD

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It automates the deployment of your applications by continuously monitoring your Git repository for changes and applying them to your Kubernetes cluster.

### ArgoCD File Structure

The ArgoCD configuration follows best practices by separating infrastructure components from application definitions:

```
kubernetes/argocd/
├── install.yaml          # ArgoCD infrastructure components
└── application.yaml      # Application definition for the React app
```

This separation ensures:
- Single source of truth for each component
- Easier maintenance and updates
- Clear separation of concerns

### Installation

To install ArgoCD, run:

```bash
./scripts/install-argocd.sh
```

This script will:
1. Create the ArgoCD namespace
2. Install ArgoCD infrastructure components with custom port configuration
3. Apply the ArgoCD Application definition to monitor your Kubernetes manifests

### Accessing ArgoCD UI

ArgoCD is deployed with a LoadBalancer service type, making it accessible outside the cluster.

You can access the ArgoCD web interface by using the LoadBalancer URL:

```bash
# Get the LoadBalancer URL
kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Visit `https://<LOADBALANCER_URL>:8443` in your browser.

If you prefer local access, you can still use port-forwarding:

```bash
kubectl port-forward svc/argocd-server -n argocd 9090:8443
```

Then navigate to https://localhost:9090 in your browser.

- Username: admin
- Password: (displayed at the end of the installation script)

### Port Configuration

ArgoCD has been configured to use the following ports to avoid conflicts with the React application:
- HTTP: 8080 (service port)
- HTTPS: 8443 (service port)
- Port-forwarding: 9090:8443 (local:remote)

### Directory Exclusions

ArgoCD is configured to exclude the following directories from synchronization:
- `argocd/*` - ArgoCD's own configuration files
- `monitoring/*` - Monitoring resources (Prometheus, Grafana) that are managed by the platform-deployment pipeline

This separation ensures that infrastructure components are managed by their dedicated pipeline while application resources are managed by ArgoCD.

### How ArgoCD Works

1. ArgoCD monitors the `kubernetes/` directory in your Git repository
2. When you push changes to your manifests, ArgoCD automatically applies them to your cluster
3. ArgoCD ensures that the actual state of your cluster matches the desired state defined in your Git repository

## Monitoring with Prometheus and Grafana

Prometheus is used for metrics collection and alerting, while Grafana provides visualization capabilities.

### Installation

To install Prometheus and Grafana, run:

```bash
./scripts/install-monitoring.sh
```

This script will:
1. Create the monitoring namespace
2. Install the kube-prometheus-stack Helm chart
3. Configure ServiceMonitors and dashboards

### Accessing Grafana

Grafana is deployed with a LoadBalancer service type, making it accessible outside the cluster.

You can access Grafana by using the LoadBalancer URL:

```bash
# Get the LoadBalancer URL
kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Visit `http://<LOADBALANCER_URL>` in your browser.

If you prefer local access, you can still use port-forwarding:

```bash
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
```

Then navigate to http://localhost:3000 in your browser.

- Username: admin
- Password: (displayed at the end of the installation script)

### Accessing Prometheus

Prometheus is deployed with a LoadBalancer service type, making it accessible outside the cluster.

You can access the Prometheus UI by using the LoadBalancer URL:

```bash
# Get the LoadBalancer URL
kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Visit `http://<LOADBALANCER_URL>:9090` in your browser.

If you prefer local access, you can still use port-forwarding:

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
```

Then navigate to http://localhost:9090 in your browser.

### Pre-configured Dashboards

1. **React App Dashboard**: A custom dashboard that shows:
   - CPU usage
   - Memory usage

2. **Standard Kubernetes Dashboards**: Automatically installed dashboards include:
   - Node metrics
   - Pod resources
   - Kubernetes cluster overview

## Integration with CI/CD Pipeline

### ArgoCD Integration

The CI/CD pipeline updates the Kubernetes deployment file with the new image tag. ArgoCD detects these changes and applies them automatically.

### Monitoring Integration

Prometheus scrapes metrics from your application using ServiceMonitors, which are configured to target your React application.

## AWS-Specific Considerations

### EKS Load Balancers

All platform services (ArgoCD, Grafana, and Prometheus) are automatically deployed with LoadBalancer services, which:

- Creates AWS Elastic Load Balancers for each service
- Makes services accessible from outside the cluster
- Provides stable DNS names for accessing services

To check your LoadBalancer endpoints:

```bash
# List all LoadBalancer services
kubectl get svc --all-namespaces | grep LoadBalancer

# Get specific service URLs
kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

For additional security, consider:
- Setting up AWS WAF in front of your Load Balancers
- Using AWS Route 53 to create friendly DNS names pointing to your LoadBalancer URLs
- Creating a Network Load Balancer with TLS termination for sensitive services like ArgoCD

### IAM Roles for Service Accounts (IRSA)

For additional AWS service access from your pods, configure IRSA:

```bash
# Example for setting up an IAM role for service accounts
eksctl create iamserviceaccount \
  --name <service-account-name> \
  --namespace <namespace> \
  --cluster <cluster-name> \
  --attach-policy-arn <policy-arn> \
  --approve
```

## Troubleshooting

### ArgoCD Issues

If applications aren't syncing properly:

```bash
kubectl get applications -n argocd
kubectl describe application react-app -n argocd
```

### Prometheus Issues

Check if ServiceMonitors are correctly configured:

```bash
kubectl get servicemonitors -n monitoring
kubectl describe servicemonitor react-app-monitor -n monitoring
```

### Grafana Issues

If dashboards aren't showing up:

```bash
kubectl get configmaps -n monitoring -l grafana_dashboard=1
```

### Docker Hub Authentication Issues

If you're having issues pulling images:

```bash
kubectl get secret dockerhub-credentials -n default -o yaml
kubectl describe pods <pod-name> | grep -A10 Events
```

### EKS-Specific Issues

If you're having issues with EKS:

```bash
# Check AWS authentication
aws sts get-caller-identity

# Check EKS cluster status
aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION

# Validate IAM role mapping for kubectl
aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.identity.oidc"
``` 
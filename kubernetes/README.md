# Kubernetes Deployment with Cosign Verification

This directory contains Kubernetes manifests for deploying the React application with secure image signature verification using Cosign.

## Components

1. **Deployment** - Manages the application pods with scaling and update strategies
2. **Service** - Exposes the application within the cluster
3. **Ingress** - Exposes the application to external traffic

## Prerequisites

- Kubernetes cluster (EKS) set up with the infrastructure deployment workflow
- Harbor registry configured for Cosign verification
- Cosign keys generated using the `scripts/generate_cosign_keys.sh` script
- cert-manager installed in the cluster (automatically done by the infrastructure workflow)

## Configuration Files

- `deployment.yaml`: Defines the application deployment with security contexts and resource limits
- `service.yaml`: Defines the Kubernetes service for the application
- `ingress.yaml`: Configures the ingress with TLS and security headers
- `cosign-verification.yaml`: Configures Cosign verification policy for container images

## Security Features

1. **Image Signature Verification**: Images are verified using Cosign signatures
2. **Security Contexts**: 
   - Non-root user
   - Read-only filesystem
   - Dropped capabilities
   - Seccomp profiles
3. **TLS**: Automatic TLS certificate issuance via cert-manager
4. **Security Headers**: HSTS, CSP, X-Frame-Options, etc.

## Deployment Instructions

### 1. Create Harbor Registry Credentials

Replace the placeholder in `deployment.yaml` with actual Harbor credentials:

```bash
kubectl create secret docker-registry harbor-registry-credentials \
  --docker-server=harbor.dev.yourdomain.com \
  --docker-username=admin \
  --docker-password=$(aws ssm get-parameter --name "/harbor/dev/admin-password" --with-decryption | jq -r '.Parameter.Value') \
  --docker-email=admin@yourdomain.com
```

### 2. Configure Cosign Verification

Update the Cosign public key in `cosign-verification.yaml`:

```bash
# Get the public key content
PUBLIC_KEY=$(cat ./cosign-keys/cosign_dev.pub)

# Replace the placeholder in the file
sed -i "s|# Replace this with your actual public key from COSIGN_PUBLIC_KEY_DEV|${PUBLIC_KEY}|" kubernetes/cosign-verification.yaml
```

### 3. Apply Kubernetes Manifests

```bash
# Apply all configurations
kubectl apply -f kubernetes/

# Verify the deployment
kubectl get pods
kubectl get deployments
kubectl get ingress
```

### 4. Verify Signature Enforcement

The deployment is configured to only pull and run container images that have been signed with the appropriate Cosign key.

## Troubleshooting

If pods are not starting due to image verification failures:

1. Check that the image was properly signed during the CI/CD pipeline
2. Verify the public key in the verification policy matches the one used for signing
3. Ensure the Harbor project has signature verification enabled

## Updating the Application

Updates to the application are handled by the CI/CD pipeline, which builds, signs, and pushes new images to Harbor. Kubernetes will automatically pull the latest signed image when the deployment is updated.

## Accessing the Application

If you're using Minikube:

```bash
minikube service tic-tac-toe --url
```

If you've set up the Ingress with a domain, access it at the configured domain (e.g., tic-tac-toe.example.com).

## Scaling

To scale the application:

```bash
kubectl scale deployment tic-tac-toe --replicas=5
```

## Monitoring

Check deployment status:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get ingress
```

View logs:

```bash
kubectl logs -l app=tic-tac-toe
```
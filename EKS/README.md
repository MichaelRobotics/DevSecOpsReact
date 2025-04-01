# Terraform EKS Cluster Setup

This directory contains Terraform configuration to deploy a minimal EKS cluster on AWS.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for interacting with the Kubernetes cluster

## Configuration

The main configuration parameters are defined in `terraform.tfvars`. You can modify these values according to your requirements:

- `region`: AWS region where the EKS cluster will be created
- `cluster_name`: Name of the EKS cluster
- `kubernetes_version`: Kubernetes version for the EKS cluster
- `instance_type`: EC2 instance type for the worker nodes
- `desired_size`: Desired number of worker nodes
- `min_size`: Minimum number of worker nodes
- `max_size`: Maximum number of worker nodes

## Deployment

Follow these steps to deploy the EKS cluster:

1. Initialize Terraform:
   ```
   terraform init
   ```

2. Preview the changes:
   ```
   terraform plan
   ```

3. Apply the changes:
   ```
   terraform apply
   ```

4. Configure kubectl to interact with your new EKS cluster:
   ```
   aws eks update-kubeconfig --region <region> --name <cluster_name>
   ```

## Testing the Cluster

Once the cluster is deployed, you can test it with:

```
kubectl get nodes
```

## Cleanup

To destroy all resources created by Terraform:

```
terraform destroy
```

## Architecture

This EKS setup includes:

- VPC with public and private subnets across 3 availability zones
- NAT Gateway for private subnet internet access
- EKS cluster with public and private endpoint access
- Managed node group with auto-scaling
- Required IAM roles and policies

## Security Considerations

- The cluster has both public and private endpoint access enabled
- Worker nodes are placed in private subnets
- A minimal set of IAM permissions is granted to the cluster and nodes 
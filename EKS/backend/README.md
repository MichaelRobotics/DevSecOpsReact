# Terraform Backend Configuration

This directory contains the Terraform configuration for setting up the backend infrastructure required to store the Terraform state remotely.

## Resources Created

- **S3 Bucket**: Stores the Terraform state files with versioning enabled
- **DynamoDB Table**: Provides state locking to prevent concurrent modifications

## Why Remote Backend?

Using a remote backend provides several benefits:

1. **State Sharing**: Multiple team members can access the same state
2. **State Locking**: Prevents concurrent state modifications
3. **State Versioning**: Keeps a history of state changes
4. **Security**: Better security practices with encrypted state

## How It Works

The workflow follows these steps:

1. This backend infrastructure is created first
2. The backend configuration is exported to the main Terraform configuration
3. The main Terraform configuration uses this backend for state management
4. During cleanup, the main infrastructure is destroyed before the backend

## Local Testing

To test this configuration locally:

```bash
# Initialize and apply the backend
cd EKS/backend
terraform init
terraform apply

# Note the outputs for S3 bucket and DynamoDB table
terraform output

# Move to the main EKS directory and create backend.tf
cd ..
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "YOUR_S3_BUCKET_NAME"
    key            = "terraform.tfstate"
    region         = "YOUR_REGION"
    dynamodb_table = "YOUR_DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

# Initialize and apply the main configuration
terraform init
terraform apply
```

## Configuration Variables

- `region`: AWS region where resources will be created (default: `us-west-1`)
- `environment`: Environment name like dev, staging, prod (default: `dev`)
- `prefix`: Prefix for resource names (default: `devsecopsreact`) 
# AWS Resource Cleanup Lambda Function

A Terraform module that provisions a Lambda function for automatically cleaning up stale AWS resources to reduce costs and maintain a clean cloud environment.

## Overview

This solution automatically identifies and removes unused AWS resources that have exceeded a configurable age threshold. It helps you:

- Reduce AWS costs by eliminating forgotten resources
- Maintain a clean and manageable cloud environment
- Automate routine cleanup tasks

## Resources Managed

The Lambda function can clean up the following stale resources:

- EC2 instances (stopped or running)
- Unattached EBS volumes
- Unused EBS snapshots
- Unused AMIs (Amazon Machine Images)

## Architecture

![Architecture Diagram](https://via.placeholder.com/800x400)

The solution consists of:

- **Lambda Function**: Python code that identifies and removes stale resources
- **IAM Role**: With necessary permissions to access and delete resources
- **CloudWatch Event Rule**: Triggers the Lambda function on a schedule

## Requirements

- AWS Account
- Terraform 0.13+
- AWS CLI configured locally

## Installation

1. Clone this repository
2. Navigate to the directory
3. Initialize Terraform
   ```
   terraform init
   ```
4. Apply the configuration
   ```
   terraform apply
   ```

## Configuration

The Lambda function behavior can be adjusted through environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `MAX_AGE_DAYS` | Resources older than this will be considered stale | 30 |
| `CLEANUP_EC2` | Enable EC2 instance cleanup | true |
| `CLEANUP_EBS` | Enable EBS volume cleanup | true |
| `CLEANUP_SNAPSHOTS` | Enable snapshot cleanup | true |
| `CLEANUP_AMIS` | Enable AMI cleanup | true |
| `DRY_RUN` | Log what would be deleted without actually removing resources | false |

## Safety Features

To prevent accidental deletion of important resources:

1. **Resource Exclusion**: Tag any resource with `ExcludeFromCleanup=true` to prevent it from being deleted
2. **Dry Run Mode**: Enable `DRY_RUN` to see what resources would be deleted without actually removing them
3. **Age Threshold**: Only resources older than `MAX_AGE_DAYS` are considered for deletion

## Example Usage

```hcl
module "resource_cleanup" {
  source = "github.com/yourusername/aws-resource-cleanup-lambda"
  
  # Optional: Override default settings
  max_age_days = 45
  cleanup_ec2 = true
  cleanup_ebs = true
  cleanup_snapshots = false  # Skip snapshot cleanup
  cleanup_amis = false       # Skip AMI cleanup
  dry_run = true             # Enable dry run mode initially
}
```

## Customization

### Adding Support for Additional Resources

To add support for cleaning up additional AWS resource types:

1. Update the IAM policy in `main.tf` with necessary permissions
2. Add a new cleanup function in `lambda_function.py`
3. Call your new function from the `lambda_handler`
4. Add a new environment variable to toggle the cleanup

Example for adding RDS instance cleanup:

```hcl
# In the IAM policy
{
  Action = [
    "rds:DescribeDBInstances",
    "rds:DeleteDBInstance"
  ],
  Effect   = "Allow",
  Resource = "*"
}
```

```python
# In lambda_function.py
def cleanup_rds_instances(rds_client):
    # Implementation here
```

## Monitoring

The Lambda function logs all activity to CloudWatch Logs. You can:

- Monitor the logs to see what resources are being deleted
- Set up CloudWatch Alarms to alert on high deletion counts
- View the execution history in the AWS Lambda console

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

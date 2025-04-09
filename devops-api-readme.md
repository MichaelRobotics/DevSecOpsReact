# DevOps Python API Examples

This repository contains a collection of Python examples for common APIs used in DevOps workflows. It serves as a reference guide for DevOps engineers looking to automate their infrastructure, deployment, and monitoring tasks.

## Table of Contents

- [Installation](#installation)
- [APIs Included](#apis-included)
- [Usage Examples](#usage-examples)
- [Complete Workflow Example](#complete-workflow-example)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)

## Installation

Clone this repository and install the required dependencies:

```bash
git clone https://github.com/yourusername/devops-python-apis.git
cd devops-python-apis
pip install -r requirements.txt
```

The requirements.txt file includes all necessary packages:

```
boto3>=1.26.0
kubernetes>=26.1.0
docker>=6.1.0
requests>=2.28.1
python-terraform>=0.10.1
python-gitlab>=3.13.0
ansible-runner>=2.3.2
datadog-api-client>=2.13.0
elasticsearch>=8.6.0
```

## APIs Included

This repository includes examples for the following DevOps APIs:

1. **AWS Boto3** - For managing AWS resources (EC2, S3, etc.)
2. **Kubernetes Python Client** - For orchestrating container deployments
3. **Docker SDK for Python** - For container management
4. **Prometheus API** - For monitoring and metrics collection
5. **Jenkins API** - For CI/CD pipeline management
6. **Terraform API** - For infrastructure as code operations
7. **GitLab API** - For source code and CI pipeline management
8. **Ansible API** - For configuration management
9. **Datadog API** - For application performance monitoring
10. **Elasticsearch API** - For log management and searching

## Usage Examples

### AWS Boto3

List and create EC2 instances:

```python
import boto3

# Initialize EC2 client
ec2 = boto3.client('ec2', 
                  region_name='us-west-2',
                  aws_access_key_id='YOUR_ACCESS_KEY',
                  aws_secret_access_key='YOUR_SECRET_KEY')

# List all EC2 instances
response = ec2.describe_instances()
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        print(f"Instance ID: {instance['InstanceId']}, State: {instance['State']['Name']}")
```

### Kubernetes Python Client

List pods in a namespace:

```python
from kubernetes import client, config

# Load kubeconfig
config.load_kube_config()
v1 = client.CoreV1Api()

# List pods
pod_list = v1.list_namespaced_pod(namespace="default")
for pod in pod_list.items:
    print(f"Pod: {pod.metadata.name}, Status: {pod.status.phase}")
```

### Docker SDK for Python

List running containers:

```python
import docker

# Initialize Docker client
docker_client = docker.from_env()

# List running containers
containers = docker_client.containers.list()
for container in containers:
    print(f"Container: {container.name}, Image: {container.image.tags}")
```

See the main Python file for more detailed examples for each API.

## Complete Workflow Example

The repository includes a comprehensive example that demonstrates how these APIs can be used together in a typical DevOps workflow:

1. Get commit information from GitLab
2. Trigger a CI/CD pipeline
3. Monitor the build with Jenkins
4. Deploy to Kubernetes
5. Configure the application with Ansible
6. Monitor deployment with Prometheus
7. Check logs in Elasticsearch

This example shows how different DevOps tools can be integrated to create a fully automated workflow from code commit to production deployment.

## Security Considerations

- **Never hardcode credentials** in your scripts. Use environment variables, AWS IAM roles, or secret management solutions.
- Use the principle of least privilege when creating API tokens and access keys.
- Regularly rotate API keys and tokens.
- Consider using tools like AWS Secrets Manager, HashiCorp Vault, or Kubernetes Secrets for managing sensitive information.

Example of loading credentials from environment variables:

```python
import os
import boto3

# Load AWS credentials from environment variables
aws_access_key = os.environ.get('AWS_ACCESS_KEY_ID')
aws_secret_key = os.environ.get('AWS_SECRET_ACCESS_KEY')

ec2 = boto3.client('ec2', 
                  region_name='us-west-2',
                  aws_access_key_id=aws_access_key,
                  aws_secret_access_key=aws_secret_key)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

# Basic Example

This example demonstrates a minimal ECS Fargate deployment with a single NGINX container.

## What it creates

- ECS Cluster with Container Insights enabled
- Fargate task definition (256 CPU / 512 MiB memory)
- ECS service running one task
- CloudWatch log group with 30-day retention
- Security group allowing inbound traffic on port 80

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Inputs

Update the `vpc_id` and `subnet_ids` values in `main.tf` to match your environment before applying.

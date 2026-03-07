# Complete Example

This example enables every feature of the module: multi-container tasks, service discovery, autoscaling, circuit breaker, ECS Exec, load balancer integration, and a sidecar container.

## What it creates

- ECS Cluster with Container Insights
- Fargate task (2048 CPU / 4096 MiB) with two containers (webapp + Datadog agent sidecar)
- ECS service with deployment circuit breaker and automatic rollback
- Cloud Map private DNS namespace and service discovery
- Application Auto Scaling (3-20 tasks, targeting 60% CPU)
- ALB target group attachment
- ECS Exec enabled
- CloudWatch log group with 365-day retention

## Usage

```bash
terraform init
terraform plan -var="vpc_id=vpc-xxx" -var='private_subnet_ids=["subnet-a","subnet-b"]' -var="target_group_arn=arn:..."
terraform apply
```

## Prerequisites

- An existing VPC with private subnets and NAT gateway
- An ALB with a target group
- ECR repositories for application images
- Secrets stored in SSM Parameter Store and/or Secrets Manager

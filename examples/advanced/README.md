# Advanced Example

This example deploys a production-grade ECS Fargate service with autoscaling, circuit breaker, ECS Exec, and a load balancer attachment.

## What it creates

- ECS Cluster with Container Insights
- Fargate task (1024 CPU / 2048 MiB) with secrets from SSM Parameter Store
- ECS service with deployment circuit breaker and automatic rollback
- Application Auto Scaling (2-10 tasks, targeting 65% CPU)
- ALB target group attachment
- ECS Exec enabled for interactive container debugging
- CloudWatch log group with 90-day retention

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Prerequisites

- An existing VPC with private subnets
- An ALB target group already provisioned
- SSM parameters for secrets stored in Parameter Store

########################################
# Complete Example — All Features Enabled
########################################

provider "aws" {
  region = "us-east-1"
}

########################################
# Supporting Resources
########################################

resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "internal.example.com"
  description = "Private DNS namespace for service discovery"
  vpc         = var.vpc_id
}

########################################
# ECS Fargate Module
########################################

module "ecs_fargate" {
  source = "../../"

  cluster_name = "complete-cluster"
  service_name = "webapp"

  task_cpu    = 2048
  task_memory = 4096

  container_definitions = [
    {
      name      = "webapp"
      image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/webapp:latest"
      cpu       = 1792
      memory    = 3584
      essential = true
      port_mappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "PORT", value = "3000" }
      ]
      secrets = [
        { name = "DATABASE_URL", valueFrom = "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/db-url" },
        { name = "API_KEY", valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/prod/api-key" }
      ]
      health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval    = 15
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    },
    {
      name      = "datadog-agent"
      image     = "public.ecr.aws/datadog/agent:latest"
      cpu       = 256
      memory    = 512
      essential = false
      port_mappings = [
        {
          containerPort = 8126
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "ECS_FARGATE", value = "true" }
      ]
      secrets = [
        { name = "DD_API_KEY", valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/prod/dd-api-key" }
      ]
    }
  ]

  # Networking
  vpc_id           = var.vpc_id
  subnet_ids       = var.private_subnet_ids
  assign_public_ip = false
  container_port   = 3000

  # Load balancer
  lb_target_group_arn = var.target_group_arn
  health_check_path   = "/health"

  # Service discovery
  enable_service_discovery = true
  namespace_id             = aws_service_discovery_private_dns_namespace.this.id

  # Autoscaling
  enable_autoscaling     = true
  min_capacity           = 3
  max_capacity           = 20
  target_cpu_utilization = 60

  # Deployment
  enable_circuit_breaker = true
  enable_execute_command = true

  # Observability
  enable_container_insights = true
  log_retention_days        = 365

  tags = {
    Environment = "production"
    Team        = "engineering"
    CostCenter  = "12345"
  }
}

########################################
# Variables
########################################

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

########################################
# Outputs
########################################

output "cluster_arn" {
  value = module.ecs_fargate.cluster_arn
}

output "service_name" {
  value = module.ecs_fargate.service_name
}

output "task_definition_arn" {
  value = module.ecs_fargate.task_definition_arn
}

output "service_discovery_arn" {
  value = module.ecs_fargate.service_discovery_arn
}

output "log_group_name" {
  value = module.ecs_fargate.log_group_name
}

output "security_group_id" {
  value = module.ecs_fargate.security_group_id
}

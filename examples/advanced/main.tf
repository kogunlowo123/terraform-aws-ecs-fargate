########################################
# Advanced Example — Autoscaling, Circuit Breaker & ECS Exec
########################################

provider "aws" {
  region = "us-east-1"
}

module "ecs_fargate" {
  source = "../../"

  cluster_name = "production-cluster"
  service_name = "api"

  task_cpu    = 1024
  task_memory = 2048

  container_definitions = [
    {
      name  = "api"
      image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/api:latest"
      port_mappings = [
        {
          containerPort = 8080
        }
      ]
      environment = [
        { name = "ENV", value = "production" },
        { name = "LOG_LEVEL", value = "info" }
      ]
      secrets = [
        { name = "DB_PASSWORD", valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/prod/db-password" }
      ]
      health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ]

  vpc_id           = "vpc-0123456789abcdef0"
  subnet_ids       = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
  assign_public_ip = false

  container_port     = 8080
  health_check_path  = "/health"
  lb_target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/api/abcdef1234567890"

  # Circuit breaker with rollback
  enable_circuit_breaker = true

  # ECS Exec for debugging
  enable_execute_command = true

  # Autoscaling
  enable_autoscaling     = true
  min_capacity           = 2
  max_capacity           = 10
  target_cpu_utilization = 65

  # Observability
  enable_container_insights = true
  log_retention_days        = 90

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}

output "cluster_arn" {
  value = module.ecs_fargate.cluster_arn
}

output "service_name" {
  value = module.ecs_fargate.service_name
}

output "task_execution_role_arn" {
  value = module.ecs_fargate.task_execution_role_arn
}

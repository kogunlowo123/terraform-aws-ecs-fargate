########################################
# Basic Example — Minimal ECS Fargate Service
########################################

provider "aws" {
  region = "us-east-1"
}

module "ecs_fargate" {
  source = "../../"

  cluster_name = "my-cluster"
  service_name = "my-app"

  task_cpu    = 256
  task_memory = 512

  container_definitions = [
    {
      name  = "app"
      image = "nginx:latest"
      port_mappings = [
        {
          containerPort = 80
        }
      ]
      environment = [
        { name = "ENV", value = "dev" }
      ]
    }
  ]

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-aaa", "subnet-bbb"]

  container_port = 80

  tags = {
    Environment = "dev"
    Project     = "demo"
  }
}

output "cluster_arn" {
  value = module.ecs_fargate.cluster_arn
}

output "service_name" {
  value = module.ecs_fargate.service_name
}

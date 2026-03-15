terraform {
  required_version = ">= 1.7.0"
}

module "test" {
  source = "../"

  cluster_name = "test-ecs-cluster"
  service_name = "test-ecs-service"
  vpc_id       = "vpc-0123456789abcdef0"
  subnet_ids   = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  container_definitions = [
    {
      name      = "app"
      image     = "nginx:latest"
      cpu       = 256
      memory    = 512
      essential = true
      port_mappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENV"
          value = "test"
        }
      ]
    }
  ]

  task_cpu    = 256
  task_memory = 512

  tags = {
    Environment = "test"
    Module      = "terraform-aws-ecs-fargate"
  }
}

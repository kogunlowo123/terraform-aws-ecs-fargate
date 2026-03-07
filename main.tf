########################################
# CloudWatch Log Group
########################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.cluster_name}/${var.service_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

########################################
# ECS Cluster
########################################

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = local.common_tags
}

########################################
# ECS Task Definition
########################################

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.cluster_name}-${var.service_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = local.rendered_container_definitions

  tags = local.common_tags
}

########################################
# Security Group
########################################

resource "aws_security_group" "ecs_service" {
  name_prefix = "${var.service_name}-ecs-"
  description = "Security group for ECS service ${var.service_name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound traffic on container port"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.service_name}-ecs"
  })

  lifecycle {
    create_before_destroy = true
  }
}

########################################
# ECS Service
########################################

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = var.assign_public_ip
  }

  # Deployment configuration with circuit breaker
  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100

    dynamic "deployment_circuit_breaker" {
      for_each = var.enable_circuit_breaker ? [1] : []
      content {
        enable   = true
        rollback = true
      }
    }
  }

  # Load balancer attachment (optional)
  dynamic "load_balancer" {
    for_each = var.lb_target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.lb_target_group_arn
      container_name   = local.primary_container_name
      container_port   = var.container_port
    }
  }

  # Service discovery (optional)
  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.this[0].arn
    }
  }

  # Ignore desired_count changes when autoscaling is managing it
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = local.common_tags
}

########################################
# Service Discovery
########################################

resource "aws_service_discovery_service" "this" {
  count = var.enable_service_discovery ? 1 : 0

  name = var.service_name

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = local.common_tags
}

########################################
# Application Auto Scaling
########################################

resource "aws_appautoscaling_target" "this" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.service_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.target_cpu_utilization
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

########################################
# CloudWatch Log Group
########################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.cluster_name}/${var.service_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
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

  tags = var.tags
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

  container_definitions = jsonencode([
    for cd in var.container_definitions : merge(
      {
        name      = cd.name
        image     = cd.image
        cpu       = try(cd.cpu, 0)
        memory    = try(cd.memory, null)
        essential = try(cd.essential, true)

        portMappings = try([
          for pm in cd.port_mappings : {
            containerPort = pm.containerPort
            hostPort      = try(pm.hostPort, pm.containerPort)
            protocol      = try(pm.protocol, "tcp")
          }
        ], [])

        environment = try([
          for env in cd.environment : {
            name  = env.name
            value = env.value
          }
        ], [])

        secrets = try([
          for s in cd.secrets : {
            name      = s.name
            valueFrom = s.valueFrom
          }
        ], [])

        command    = try(cd.command, null)
        entryPoint = try(cd.entry_point, null)

        dependsOn = try([
          for d in cd.depends_on : {
            containerName = d.containerName
            condition     = d.condition
          }
        ], null)

        mountPoints = try(cd.mount_points, [])
        volumesFrom = try(cd.volumes_from, [])

        healthCheck = try(cd.health_check, null) != null ? {
          command     = cd.health_check.command
          interval    = try(cd.health_check.interval, 30)
          timeout     = try(cd.health_check.timeout, 5)
          retries     = try(cd.health_check.retries, 3)
          startPeriod = try(cd.health_check.startPeriod, 0)
        } : null

        logConfiguration = try(cd.log_configuration, null) != null ? cd.log_configuration : {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.this.name
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = cd.name
          }
        }
      }
    )
  ])

  tags = var.tags
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

  tags = merge(var.tags, {
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

  dynamic "load_balancer" {
    for_each = var.lb_target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.lb_target_group_arn
      container_name   = var.container_definitions[0].name
      container_port   = var.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.this[0].arn
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
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

  tags = var.tags
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

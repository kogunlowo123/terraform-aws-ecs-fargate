locals {
  # Derive the "primary" container name from the first definition.
  primary_container_name = var.container_definitions[0].name

  # Build the JSON-encoded container definitions, injecting a default
  # awslogs log configuration when the caller has not provided one.
  rendered_container_definitions = jsonencode([
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

  common_tags = merge(
    {
      "terraform"   = "true"
      "ecs:cluster" = var.cluster_name
      "ecs:service" = var.service_name
    },
    var.tags,
  )
}

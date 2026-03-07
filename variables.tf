########################################
# Cluster
########################################

variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

########################################
# Service
########################################

variable "service_name" {
  description = "Name of the ECS service."
  type        = string
}

########################################
# Task Definition
########################################

variable "task_cpu" {
  description = "CPU units for the Fargate task (e.g. 256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task."
  type        = number
  default     = 512
}

variable "container_definitions" {
  description = <<-EOT
    List of container definition objects. Each object supports:
      - name              (string, required)
      - image             (string, required)
      - cpu               (number, optional)
      - memory            (number, optional)
      - essential         (bool, optional, default true)
      - port_mappings     (list of objects with containerPort, protocol, optional hostPort)
      - environment       (list of objects with name, value)
      - secrets           (list of objects with name, valueFrom)
      - health_check      (object with command, interval, timeout, retries, startPeriod)
      - mount_points      (list of objects)
      - volumes_from      (list of objects)
      - command           (list of strings)
      - entry_point       (list of strings)
      - depends_on        (list of objects with containerName, condition)
      - log_configuration (object — overrides the default awslogs configuration)
  EOT
  type        = any
}

########################################
# Networking
########################################

variable "vpc_id" {
  description = "VPC ID where the ECS service will run."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service network configuration."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the ENI of the task."
  type        = bool
  default     = false
}

########################################
# Service Discovery
########################################

variable "enable_service_discovery" {
  description = "Enable AWS Cloud Map service discovery."
  type        = bool
  default     = false
}

variable "namespace_id" {
  description = "Cloud Map namespace ID (required when enable_service_discovery is true)."
  type        = string
  default     = ""
}

########################################
# Autoscaling
########################################

variable "enable_autoscaling" {
  description = "Enable Application Auto Scaling for the ECS service."
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number of tasks when autoscaling is enabled."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks when autoscaling is enabled."
  type        = number
  default     = 4
}

variable "target_cpu_utilization" {
  description = "Target average CPU utilization (%) for the autoscaling policy."
  type        = number
  default     = 70
}

########################################
# Deployment / Circuit Breaker
########################################

variable "enable_circuit_breaker" {
  description = "Enable the ECS deployment circuit breaker with rollback."
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for interactive debugging."
  type        = bool
  default     = false
}

########################################
# Load Balancer
########################################

variable "lb_target_group_arn" {
  description = "ARN of the ALB/NLB target group. Leave empty to skip LB attachment."
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Container port exposed by the primary container (used for LB and SG)."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP health check path for the load balancer target group."
  type        = string
  default     = "/health"
}

########################################
# Observability
########################################

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights on the ECS cluster."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log events."
  type        = number
  default     = 30
}

########################################
# Tags
########################################

variable "tags" {
  description = "Map of tags applied to all resources."
  type        = map(string)
  default     = {}
}

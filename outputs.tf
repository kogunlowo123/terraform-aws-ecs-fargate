########################################
# Cluster
########################################

output "cluster_id" {
  description = "ID of the ECS cluster."
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

########################################
# Service
########################################

output "service_id" {
  description = "ID of the ECS service."
  value       = aws_ecs_service.this.id
}

output "service_arn" {
  description = "ARN of the ECS service."
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

########################################
# Task Definition
########################################

output "task_definition_arn" {
  description = "Full ARN of the task definition (includes revision)."
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Family of the task definition."
  value       = aws_ecs_task_definition.this.family
}

output "task_definition_revision" {
  description = "Revision number of the task definition."
  value       = aws_ecs_task_definition.this.revision
}

########################################
# IAM
########################################

output "task_execution_role_arn" {
  description = "ARN of the task execution IAM role."
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the task IAM role."
  value       = aws_iam_role.task.arn
}

########################################
# Networking
########################################

output "security_group_id" {
  description = "ID of the security group attached to the ECS service."
  value       = aws_security_group.ecs_service.id
}

########################################
# CloudWatch
########################################

output "log_group_name" {
  description = "Name of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.arn
}

########################################
# Service Discovery
########################################

output "service_discovery_arn" {
  description = "ARN of the Cloud Map service discovery service (empty when disabled)."
  value       = var.enable_service_discovery ? aws_service_discovery_service.this[0].arn : ""
}

########################################
# Autoscaling
########################################

output "autoscaling_target_resource_id" {
  description = "Resource ID of the autoscaling target (empty when disabled)."
  value       = var.enable_autoscaling ? aws_appautoscaling_target.this[0].resource_id : ""
}

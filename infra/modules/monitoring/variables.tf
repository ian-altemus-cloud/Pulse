variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}

variable "health_endpoint" {
  description = "ALB health endpoint URL to monitor"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for CloudWatch alarms"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name for CloudWatch alarms"
  type        = string
}
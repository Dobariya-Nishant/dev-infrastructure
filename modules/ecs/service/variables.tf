# ==================
# General Deployment
# ==================
variable "project_name" {
  type        = string
  description = "Base name for ECS service, tasks, and resources"
}

variable "name" {
  type        = string
  description = "Base name for ECS service, tasks, and resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for ECS service networking"
}

variable "security_groups" {
  description = "List of securety groups IDs for ECS Service"
  type        = list(string)
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Number of ECS task instances to run"
}

variable "capacity_provider_name" {
  type        = string
  default     = null
  description = "Optional ECS capacity provider name"
}

variable "health_check_grace_period_seconds" {
  type        = number
  default     = null
  description = "Optional how much time to wait for running health check"
}

variable "capacity_provider_strategy" {
  type        = string
  default     = null
  description = "Optional how much time to wait for running health check"
}

variable "container_name" {
  type        = string
  description = "Optional how much time to wait for running health check"
}

variable "task_definition_arn" {
  type        = string
  description = "Optional how much time to wait for running health check"
}

variable "alb_blue_tg_arn" {
  type        = string
  description = "Optional how much time to wait for running health check"
}

variable "container_port" {
  type = number
}

# ========================
# ECS Cluster
# ========================
variable "ecs_cluster_id" {
  type        = string
  description = "ID of the ECS cluster where service will run"
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}
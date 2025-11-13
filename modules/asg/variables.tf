# ==========================
# Core Project Configuration
# ==========================

variable "project_name" {
  description = "Name of the overall project. Used for consistent naming and tagging across all resources."
  type        = string
}

variable "name" {
  description = "Base name used as an identifier for all resources (e.g., key name, launch template name, etc.)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod). Used for tagging and naming consistency."
  type        = string
}

# ==========
# Networking
# ==========

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group to launch instances in. Determines availability zones."
  type        = list(string)
}

variable "security_groups" {
  description = "List of security IDs for the Auto Scaling Group."
  type        = list(string)
}


# =======================
# EC2 & AMI Configuration
# =======================

variable "instance_type" {
  description = "EC2 instance type to launch (e.g., t3.micro, m5.large)."
  type        = string
  default     = "t3.micro"
}

variable "ecs_user_data" {
  description = "user custom script that runs after starting EC2"
  type        = string
  default     = ""
}

variable "ebs_type" {
  description = "EBS volume type (e.g., gp2, gp3, io1) attached to EC2 instances."
  type        = string
  default     = "gp2"
}

variable "ebs_size" {
  description = "Size (in GB) of the root EBS volume attached to EC2 instances."
  type        = string
  default     = 30
}

variable "use_spot" {
  description = "Use EC2 Spot Instances for cost optimization. Set to true to enable."
  type        = bool
  default     = false
}

# ===============
# ECS Integration
# ===============

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to register the EC2 instances to. If set, ECS-specific AMI and user data will be used."
  type        = string
  default     = null
}

# ==================
# Auto Scaling Group
# ==================

variable "desired_capacity" {
  description = "Number of instances the Auto Scaling Group should launch initially."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances the Auto Scaling Group can scale up to."
  type        = number
  default     = 6
}

variable "min_size" {
  description = "Minimum number of instances the Auto Scaling Group should maintain."
  type        = number
  default     = 1
}
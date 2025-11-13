# =============================
# 🧱 Core Project Configuration
# =============================

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

# =============
# 🌐 Networking
# =============

variable "vpc_id" {
  description = "The VPC ID where resources like EC2, ALB, and security groups will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to launch the ALB and associated resources into. Typically across multiple AZs."
  type        = list(string)
}

variable "security_groups" {
  description = "List of security groups IDs to allow traffic in ALB"
  type        = list(string)
}

variable "internal" {
  description = "List of security groups IDs to allow traffic in ALB"
  type        = bool
  default     = true
}

# ======================
# 🌐 Hosted Zone for DNS
# ======================

variable "acm_certificate_arn" {
  description = "Acm certificate for HTTPS"
  type        = string
  default     = null
}

variable "hostedzone_id" {
  description = "Route53 Hosted Zone ID for your domain"
  type        = string
  default     = null
}

variable "domain_names" {
  description = "Domain name for ALB (example.com)"
  type        = list(string)
  default     = []
}

# =============
# Target Groups
# =============

variable "target_groups" {
  description = "Map of target group definitions for blue/green"
  type = map(object({
    name              = string # name suffix for TG
    port              = number # port to listen on
    protocol          = string # HTTP or HTTPS
    target_type       = string # instance or ip
    enable_http1      = optional(bool, false) # for HTTP1 use only
    health_check_path = optional(string, "/")
  }))
}

# =========
# Listeners
# =========

variable "listener" {
  description = "Listener settings for ALB"
  type = object({
    name             = string
    enable_https     = optional(bool, false)
    target_group_key = string # default target group key to forward HTTPS traffic
    rules = optional(map(object({
      description      = string
      target_group_key = string
      patterns         = optional(list(string))
      hosts            = optional(list(string))
    })),{})
  })
}
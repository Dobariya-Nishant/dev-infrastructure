variable "project_name" {
  description = "The name of the project. Used consistently for naming, tagging, and organizational purposes across resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g., dev, staging, prod). Used for environment-specific tagging and naming."
  type        = string
}



variable "username" {
  description = "Master username for the DB"
  type        = string
}

variable "password" {
  description = "Master password for the DB"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of subnet IDs in your VPC"
  type        = list(string)
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Dev only
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GB"
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17.6"
}

variable "security_groups" {
  description = "List of securety groups IDs for ECS Service"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether DB is publicly accessible"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  type        = string
  description = "Base name for ECS service, tasks, and resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
}

variable "family" {
  description = "A unique name for your task definition."
  type        = string
}

variable "task_role_arn" {
  description = "IAM role that grants containers in the task permission to call AWS APIs."
  type        = string
  default     = null
}

variable "network_mode" {
  description = "The Docker networking mode to use for the containers in the task."
  type        = string
  default     = "awsvpc"
}

variable "requires_compatibilities" {
  description = "Launch types required by the task."
  type        = list(string)
  default     = ["FARGATE"]
}

variable "cpu" {
  description = "The number of CPU units used by the task."
  type        = string
  default     = "256"
}

variable "memory" {
  description = "The amount of memory (in MiB) used by the task."
  type        = string
  default     = "512"
}

variable "containers" {
  description = "List of container definitions for the ECS task (camelCase for ECS API)."
  type = list(object({
    name              = string
    image             = string
    essential         = optional(bool, true)
    cpu               = optional(number)
    memory            = optional(number)
    memoryReservation = optional(number)
    command           = optional(list(string))
    entryPoint        = optional(list(string))
    workingDirectory  = optional(string)

    portMappings = optional(list(object({
      containerPort = number
      hostPort      = optional(number)
      protocol      = optional(string, "tcp")
    })))

    environment = optional(list(object({
      name  = string
      value = string
    })), [])

    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])

    mountPoints = optional(list(object({
      sourceVolume  = string
      containerPath = string
      readOnly      = optional(bool)
    })), [])

    logConfiguration = optional(object({
      logDriver = string
      options   = optional(map(string))
    }))

    healthCheck = optional(object({
      command     = optional(list(string))
      interval    = optional(number)
      timeout     = optional(number)
      retries     = optional(number)
      startPeriod = optional(number)
    }))
  }))
}


variable "secrets_read_arns" {
  description = "List of Secrets Manager ARNs the ECS task should be able to read"
  type        = list(string)
  default     = []
}

variable "ephemeral_storage_size" {
  description = "Ephemeral storage size (GiB) for Fargate tasks."
  type        = number
  default     = null
}

variable "placement_constraints" {
  description = "Task placement constraints."
  type = list(object({
    type       = string
    expression = optional(string)
  }))
  default = []
}

variable "volumes" {
  description = "List of volume configurations for the task."
  type = list(object({
    name      = string
    host_path = optional(string)
    efs_volume_configuration = optional(object({
      file_system_id          = string
      root_directory          = optional(string)
      transit_encryption      = optional(string)
      transit_encryption_port = optional(number)
      authorization_config = object({
        access_point_id = optional(string)
        iam             = optional(string)
      })
    }))
    docker_volume_configuration = optional(object({
      scope         = optional(string)
      autoprovision = optional(bool)
      driver        = optional(string)
      driver_opts   = optional(map(string))
      labels        = optional(map(string))
    }))
  }))
  default = []
}

variable "pid_mode" {
  description = "The process namespace to use for the containers."
  type        = string
  default     = null
}

variable "ipc_mode" {
  description = "The IPC resource namespace to use for the containers."
  type        = string
  default     = null
}

variable "proxy_configuration" {
  description = "Proxy configuration for App Mesh."
  type = object({
    type           = string
    container_name = string
    properties     = map(string)
  })
  default = null
}

variable "runtime_platform" {
  description = "Runtime platform configuration."
  type = object({
    cpu_architecture        = string
    operating_system_family = string
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to the ECS task definition."
  type        = map(string)
  default     = {}
}

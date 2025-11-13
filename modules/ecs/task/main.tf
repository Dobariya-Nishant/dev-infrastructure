resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-${var.family}-td-${var.environment}"
  task_role_arn            = var.task_role_arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.cpu
  memory                   = var.memory

  # Container definitions (as JSON)
  container_definitions = jsonencode(var.containers)

  # Optional ephemeral storage
  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size == null ? [] : [1]
    content {
      size_in_gib = var.ephemeral_storage_size
    }
  }

  # Optional volumes
  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = efs_volume_configuration.value.root_directory
          transit_encryption      = efs_volume_configuration.value.transit_encryption
          transit_encryption_port = efs_volume_configuration.value.transit_encryption_port
          authorization_config {
            access_point_id = efs_volume_configuration.value.authorization_config.access_point_id
            iam             = efs_volume_configuration.value.authorization_config.iam
          }
        }
      }

      dynamic "docker_volume_configuration" {
        for_each = volume.value.docker_volume_configuration != null ? [volume.value.docker_volume_configuration] : []
        content {
          scope         = docker_volume_configuration.value.scope
          autoprovision = docker_volume_configuration.value.autoprovision
          driver        = docker_volume_configuration.value.driver
          driver_opts   = docker_volume_configuration.value.driver_opts
          labels        = docker_volume_configuration.value.labels
        }
      }
    }
  }

  pid_mode = var.pid_mode
  ipc_mode = var.ipc_mode

  tags = {
    Name = "${var.project_name}-${var.family}-td-${var.environment}"
  }
}

# ====================
# IAM Roles & Policies
# ====================

# IAM role trust policy for ECS task execution role
data "aws_iam_policy_document" "ecs_task_execution_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-${var.family}-task-execution-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json

  tags = {
    Name = "${var.project_name}-${var.family}-task-execution-role-${var.environment}"
  }
}

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_execution_policy_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role_policy.arn
}

resource "aws_iam_role_policy" "ecs_secrets_access" {
  count = length(var.secrets_read_arns) > 0 ? 1 : 0
  name  = "${var.project_name}-ecs-secrets-access-${var.environment}"
  role  = aws_iam_role.ecs_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_read_arns
      }
    ]
  })
}


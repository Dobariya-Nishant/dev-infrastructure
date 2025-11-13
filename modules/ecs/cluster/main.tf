# ===========
# ECS Cluster
# ===========

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }

  tags = {
    Name = "${var.project_name}-cluster-${var.environment}"
  }
}

# ==============================
# ECS Capacity Providers for EC2
# ==============================

# Creates capacity providers for each ASG passed in
resource "aws_ecs_capacity_provider" "this" {
  for_each = var.auto_scaling_groups

  name = "${var.project_name}-${each.value.name}-cp-${var.environment}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = each.value.arn
    managed_termination_protection = "ENABLED"
    managed_draining               = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = each.value.target_capacity
    }
  }

  tags = {
    Name = "${var.project_name}-${each.value.name}-cp-${var.environment}"
  }
}

# ========================================
# Attach Capacity Providers to ECS Cluster
# ========================================

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = concat(
    [for cp in aws_ecs_capacity_provider.this : cp.name],
    ["FARGATE"]
  )

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}


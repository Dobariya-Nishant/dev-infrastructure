# ============
# ECS Services
# ============

resource "aws_ecs_service" "this" {
  name                              = "${var.project_name}-${var.name}-sv-${var.environment}"
  cluster                           = var.ecs_cluster_id
  task_definition                   = var.task_definition_arn
  desired_count                     = var.desired_count
  health_check_grace_period_seconds = 200
  force_new_deployment = true

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_groups
    assign_public_ip = false
  }

  capacity_provider_strategy {
    capacity_provider = try(var.capacity_provider_strategy, "FARGATE") 
    weight            = 2
  }

  deployment_controller {
    type = "CODE_DEPLOY" 
  }

  load_balancer {
    container_name   = var.container_name
    target_group_arn = var.alb_blue_tg_arn
    container_port   = var.container_port
  }
 
  lifecycle {
    ignore_changes = [load_balancer]
  }

  tags = {
    Name = "${var.project_name}-${var.name}-sv-${var.environment}"
  }
}

# ==========================
# Auto Scaling (ECS Service)
# ==========================

# Register ECS Service as scalable
resource "aws_appautoscaling_target" "ecs_service" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based auto-scaling policy
resource "aws_appautoscaling_policy" "cpu_scaling" {
  name               = "${aws_ecs_service.this.name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 80.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 15
    scale_out_cooldown = 15
  }
}

# Memory-based auto-scaling policy
resource "aws_appautoscaling_policy" "memory_scaling" {
  name               = "${aws_ecs_service.this.name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 80.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 15
    scale_out_cooldown = 15
  }
}


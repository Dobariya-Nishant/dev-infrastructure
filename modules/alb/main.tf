# ===================================
# 🏗️  Application Load Balancer (ALB)
# ===================================

resource "aws_lb" "this" {
  name                             = "${var.project_name}-${var.name}-alb-${var.environment}"
  internal                         = var.internal
  load_balancer_type               = "application"
  security_groups                  = var.security_groups
  subnets                          = var.subnet_ids
  idle_timeout                     = 300
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-${var.name}-alb-${var.environment}"
  }
}

# ====================================
# 🎯 Target Groups (for ALB Listeners)
# ====================================

resource "aws_lb_target_group" "blue" {
  for_each = var.target_groups

  name                          = "${var.project_name}-blue-${each.value.name}-tg-${var.environment}"
  port                          = each.value.port
  protocol                      = each.value.protocol
  vpc_id                        = var.vpc_id
  target_type                   = each.value.target_type
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    interval            = 15
    path                = each.value.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-blue-${each.value.name}-tg-${var.environment}"
  }
}

resource "aws_lb_target_group" "green" {
  for_each = var.target_groups

  name                          = "${var.project_name}-green-${each.value.name}-tg-${var.environment}"
  port                          = each.value.port
  protocol                      = each.value.protocol
  vpc_id                        = var.vpc_id
  target_type                   = each.value.target_type
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    interval            = 15
    path                = each.value.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-green-${each.value.name}-tg-${var.environment}"
  }
}

# ================================
# 🎧 ALB Listeners (Port 80 / 443)
# ================================

resource "aws_lb_listener" "https" {
  count = var.listener.enable_https == true ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[var.listener.target_group_key].arn
  }

  tags = {
    Name = "${var.project_name}-${var.listener.name}-https-${var.environment}"
  }
}

# HTTP listener -> Redirect to HTTPS
resource "aws_lb_listener" "https_redirect" {
  count = var.listener.enable_https == true ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.listener.name}-http-${var.environment}"
  }
}

resource "aws_lb_listener" "http" {
  count = var.listener.enable_https == false ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[var.listener.target_group_key].arn
  }

  tags = {
    Name = "${var.project_name}-${var.listener.name}-https-${var.environment}"
  }
}

# ==========================================
# 📜 ALB Listener Rules (Path-based Routing)
# ==========================================

resource "aws_lb_listener_rule" "this" {
  for_each = var.listener.rules

  listener_arn = var.listener.enable_https == true ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[each.value.target_group_key].arn
  }

  condition {
    dynamic "path_pattern" {
      for_each = try(each.value.patterns, null) != null ? [1] : []
      content {
        values = each.value.patterns
      }
    }

    dynamic "host_header" {
      for_each = try(each.value.hosts, null) != null ? [1] : []
      content {
        values = each.value.hosts
      }
    }
  }

  tags = {
    Description = each.value.description
  }
}

# ========================================
# 7. Route53 record to point domain to ALB
# ========================================
resource "aws_route53_record" "alias" {
  count = var.hostedzone_id != null ? length(var.domain_names) : 0

  zone_id = var.hostedzone_id
  name    = var.domain_names[count.index]
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}


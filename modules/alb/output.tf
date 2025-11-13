output "id" {
  description = "Application Load Balancer ID."
  value       = aws_lb.this.id
}

output "listener_arn" {
  description = "ARN of the ALB HTTPS listener."
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "blue_tg" {
  description = "the blue (active) target groups"
  value = {
    for k, tg in aws_lb_target_group.blue :
    k => {
      name = tg.name
      arn  = tg.arn
    }
  }
}

output "green_tg" {
  description = "the green (test) target groups"
  value = {
    for k, tg in aws_lb_target_group.green :
    k => {
      name = tg.name
      arn  = tg.arn
    }
  }
}
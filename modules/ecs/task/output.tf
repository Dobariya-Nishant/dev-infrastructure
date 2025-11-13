output "id" {
  value = aws_ecs_task_definition.this.id
}

output "family" {
  value = aws_ecs_task_definition.this.family
}

output "arn" {
  value = aws_ecs_task_definition.this.arn
}

output "revision" {
  value = aws_ecs_task_definition.this.revision
}
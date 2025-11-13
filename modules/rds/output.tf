output "endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Database port"
  value       = aws_db_instance.this.port
}

output "username" {
  value = var.username
}

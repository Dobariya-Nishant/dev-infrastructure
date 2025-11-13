# -------------------------------------------------------------------
# Cheapest RDS PostgreSQL Single-AZ (No TLS, No Encryption)
# -------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
  }
}

resource "aws_db_instance" "this" {
  identifier              = "${var.project_name}-db-${var.environment}"
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  username                = var.username
  password                = var.password
  allocated_storage       = var.allocated_storage
  storage_type            = "gp2"
  publicly_accessible     = var.publicly_accessible
  multi_az                = false
  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true

  # Disable encryption/TLS
  storage_encrypted       = false
  iam_database_authentication_enabled = false
  ca_cert_identifier      = null  # Disable TLS enforcement

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.security_groups

  tags = {
      Name = "${var.project_name}-db-${var.environment}"
    }
}

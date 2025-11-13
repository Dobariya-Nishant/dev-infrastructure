output "id" {
  value = aws_vpc.this.id
}

output "public_sub_ids" {
  value = aws_subnet.public[*].id
}

output "private_sub_ids" {
  value = aws_subnet.private[*].id
}

output "frontend_sub_ids" {
  value = aws_subnet.frontend[*].id
}

output "backend_sub_ids" {
  value = aws_subnet.backend[*].id
}

output "asg_sub_ids" {
  value = aws_subnet.asg[*].id
}

output "database_sub_ids" {
  value = aws_subnet.database[*].id
}

output "frontend_alb_sg_id" {
  value = aws_security_group.frontend_alb.id
}

output "backend_alb_sg_id" {
  value = aws_security_group.backend_alb.id
}

output "asg_sg_id" {
  value = aws_security_group.asg.id
}

output "bastion_ec2_sg_id" {
  value = aws_security_group.bastion_ec2.id
}

output "frontend_sg_id" {
  value = aws_security_group.frontend.id
}

output "backend_sg_id" {
  value = aws_security_group.backend.id
}

output "docdb_sg_id" {
  value = aws_security_group.docdb.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

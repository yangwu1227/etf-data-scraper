output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.private.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.public.id
}

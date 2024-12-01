output "ecs_fargate_cluster_name" {
  description = "The name of the ECS Fargate cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_fargate_task_definition_family" {
  description = "The name of the ECS Fargate task definition family"
  value       = aws_ecs_task_definition.ecs_task_definition.family
}

output "ecs_fargate_container_name" {
  description = "The name of the ECS Fargate container"
  value       = "${var.stack_name}_container"
}

output "ecs_task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ECS task role ARN"
}

output "ecs_execution_role_arn" {
  value       = aws_iam_role.ecs_execution_role.arn
  description = "ECS execution role ARN"
}

output "ec2_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_profile.name
  description = "EC2 instance profile name"
}

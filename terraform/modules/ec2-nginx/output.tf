output "ec2_target_group_arn" {
  description = "Target group ARN for EC2 NGINX"
  value       = aws_lb_target_group.ec2_tg.arn
}

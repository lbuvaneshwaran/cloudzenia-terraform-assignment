output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB"
  value       = aws_lb.this.zone_id
}

output "alb_sg_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb_sg.id
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS listener ARN"
  value       = aws_lb_listener.https.arn
}

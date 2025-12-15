# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "cloudzenia-alb-sg"
  description = "Allow HTTP and HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "cloudzenia-alb-sg"
  })
}

# Application Load Balancer
resource "aws_lb" "this" {
  name               = "cloudzenia-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb_sg.id]

  tags = merge(var.tags, {
    Name = "cloudzenia-alb"
  })
}

# resource "aws_acm_certificate" "this" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"
#
#   tags = {
#     Name = "cloudzenia-cert"
#   }
# }

# HTTPS Listener
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.this.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate.this.arn
#
#   default_action {
#     type = "fixed-response"
#
#     fixed_response {
#       content_type = "text/plain"
#       message_body = "Service is healthy"
#       status_code  = "200"
#     }
#   }
# }


# HTTP → HTTPS Redirect
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "ALB is running"
      status_code  = "200"
    }
  }
}


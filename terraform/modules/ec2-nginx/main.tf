############################################
# SECURITY GROUP – EC2 (LEAST PRIVILEGE)
############################################
resource "aws_security_group" "ec2_sg" {
  name   = "cloudzenia-ec2-sg"
  vpc_id = var.vpc_id

  # Allow traffic ONLY from ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloudzenia-ec2-sg"
  }
}

############################################
# EC2 INSTANCES (2 – PRIVATE SUBNET)
############################################
resource "aws_instance" "ec2" {
  count         = 2
  ami           = "ami-00ca570c1b6d79f36" # Amazon Linux 2 – ap-south-1
  instance_type = "t3.micro"
  subnet_id     = var.private_subnet_ids[count.index]

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # IAM ROLE FOR CLOUDWATCH + SSM
  iam_instance_profile = var.ec2_instance_profile_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Install Docker
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker

              # Run Docker container
              docker run -d -p 8080:8080 hashicorp/http-echo -text="Namaste from Container"

              # Install NGINX
              yum install nginx -y

              # DOMAIN BASED ROUTING (IMPORTANT)
              cat <<NGINX > /etc/nginx/conf.d/default.conf
              server {
                  listen 80;
                  server_name ec2-instance.meghora.com;

                  location / {
                      return 200 "Hello from Instance";
                  }
              }

              server {
                  listen 80;
                  server_name ec2-docker.meghora.com;

                  location / {
                      proxy_pass http://localhost:8080;
                  }
              }
              NGINX

              systemctl restart nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "cloudzenia-ec2-${count.index + 1}"
  }
}

############################################
# TARGET GROUP – EC2 (NGINX)
############################################
resource "aws_lb_target_group" "ec2_tg" {
  name     = "tg-ec2-nginx"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "tg-ec2-nginx"
  }
}

############################################
# TARGET GROUP ATTACHMENTS
############################################
resource "aws_lb_target_group_attachment" "ec2_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.ec2_tg.arn
  target_id        = aws_instance.ec2[count.index].id
  port             = 80
}


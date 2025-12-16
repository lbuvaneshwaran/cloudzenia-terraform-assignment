# Security Group (Least Privilege)
resource "aws_security_group" "ec2_sg" {
  name   = "cloudzenia-ec2-sg"
  vpc_id = var.vpc_id

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
}
# EC2 Instances (2 instances)
resource "aws_instance" "ec2" {
  count         = 2
  ami           = "ami-0f5ee92e2d63afc18" # Amazon Linux 2 (ap-south-1)
  instance_type = "t3.micro"
  subnet_id     = var.private_subnet_ids[count.index]

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker

              docker run -d -p 8080:8080 hashicorp/http-echo -text="Namaste from Container"

              yum install nginx -y
              cat <<NGINX > /etc/nginx/conf.d/default.conf
              server {
                  listen 80;

                  location / {
                      return 200 "Hello from Instance";
                  }

                  location /docker {
                      proxy_pass http://localhost:8080;
                  }
              }
              NGINX

              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "cloudzenia-ec2-${count.index + 1}"
  }
}
# Target Group (EC2)
resource "aws_lb_target_group" "ec2_tg" {
  name     = "tg-ec2-nginx"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}
# Attach EC2 to Target Group

resource "aws_lb_target_group_attachment" "ec2_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.ec2_tg.arn
  target_id        = aws_instance.ec2[count.index].id
  port             = 80
}


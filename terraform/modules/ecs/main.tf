#################################
# ECS CLUSTER
#################################
resource "aws_ecs_cluster" "this" {
  name = "cloudzenia-ecs-cluster-${var.env}"

  tags = var.tags
}

#################################
# ECS SECURITY GROUP
#################################
resource "aws_security_group" "ecs_sg" {
  name   = "cloudzenia-ecs-sg-${var.env}"
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

  tags = var.tags
}

#################################
# TARGET GROUPS
#################################
resource "aws_lb_target_group" "wordpress" {
  name        = "tg-wordpress-${var.env}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_target_group" "microservice" {
  name        = "tg-microservice-${var.env}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

#################################
# LISTENER RULES
#################################
resource "aws_lb_listener_rule" "wordpress" {
  listener_arn = var.https_listener_arn
  priority     = 10

  condition {
    host_header {
      values = ["wordpress.${var.domain_name}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

resource "aws_lb_listener_rule" "microservice" {
  listener_arn = var.https_listener_arn
  priority     = 20

  condition {
    host_header {
      values = ["microservice.${var.domain_name}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.microservice.arn
  }
}

#################################
# TASK DEFINITIONS
#################################
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress-task-${var.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

    container_definitions = jsonencode([
    {
      name  = "wordpress"
      image = "wordpress:latest"

      portMappings = [{
        containerPort = 80
      }]
    logConfiguration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = "/ecs/wordpress-dev"
      awslogs-region        = "ap-south-1"
      awslogs-stream-prefix = "wordpress"
    }
  }
      environment = [
        { name = "WORDPRESS_DB_HOST", value = var.db_endpoint },
        { name = "WORDPRESS_DB_NAME", value = "wordpress" }
      ]

      secrets = [
        {
          name      = "WORDPRESS_DB_USER"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "WORDPRESS_DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ]
    }
  ])

}

resource "aws_ecs_task_definition" "microservice" {
  family                   = "microservice-task-${var.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "microservice"
      image = var.microservice_image
      portMappings = [{ containerPort = 3000 }]
    }
  ])
}

#################################
# ECS SERVICES
#################################
resource "aws_ecs_service" "wordpress" {
  name            = "wordpress-service-${var.env}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 180

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress.arn
    container_name   = "wordpress"
    container_port   = 80
  }
}

resource "aws_ecs_service" "microservice" {
  name            = "microservice-service-${var.env}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.microservice.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 180

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.microservice.arn
    container_name   = "microservice"
    container_port   = 3000
  }
}

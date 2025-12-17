############################################
# ROOT MODULE – DEV ENVIRONMENT
############################################

# AWS ACCOUNT ID
data "aws_caller_identity" "current" {}

# ROUTE 53 HOSTED ZONE
data "aws_route53_zone" "main" {
  name         = "meghora.com"
  private_zone = false
}

############################################
# VPC
############################################
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr = "10.0.0.0/16"

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  azs = ["ap-south-1a", "ap-south-1b"]

  tags = {
    Project = "Cloudzenia-Assignment"
    Env     = "dev"
  }
}

############################################
# ALB + ACM + ROUTE53
############################################
module "alb" {
  source = "../../modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  domain_name = "meghora.com"
  zone_id     = data.aws_route53_zone.main.zone_id

  tags = {
    Project = "Cloudzenia-Assignment"
    Env     = "dev"
  }
}
# Application Security Group
resource "aws_security_group" "app_sg" {
  name        = "cloudzenia-app-sg"
  description = "Security group for application layer (ECS & EC2)"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "Cloudzenia-Assignment"
    Env     = "dev"
  }
}


############################################
# SECRETS MANAGER
############################################
module "secrets" {
  source = "../../modules/secrets"

  env         = "dev"
  db_username = "wpuser"
  db_password = "WpPassword123!"
}

############################################
# IAM (ECS + EC2)
############################################
module "iam" {
  source = "../../modules/iam"

  env           = "dev"
  db_secret_arn = module.secrets.secret_arn
}


############################################
# RDS (NO ECS DEPENDENCY ❗)
############################################
module "rds" {
  source = "../../modules/rds"

  env                = "dev"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  app_sg_id          = aws_security_group.app_sg.id

  db_username        = "wpuser"
  db_password        = "WpPassword123!"

  tags = {
    Project = "Cloudzenia-Assignment"
    Env     = "dev"
  }
}


############################################
# ECS – SECTION 1
############################################
module "ecs" {
  source = "../../modules/ecs"

  env         = "dev"
  domain_name = "meghora.com"

  tags = {
    Project = "Cloudzenia-Assignment"
    Env     = "dev"
  }

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.alb.alb_sg_id

  https_listener_arn = module.alb.https_listener_arn

  task_role_arn      = module.iam.ecs_task_role_arn
  execution_role_arn = module.iam.ecs_execution_role_arn

  db_endpoint   = module.rds.rds_endpoint
  db_secret_arn = module.secrets.secret_arn

  microservice_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-south-1.amazonaws.com/cloudzenia-microservice:latest"

  depends_on = [
    module.alb,
    module.rds
  ]
}

############################################
# EC2 + NGINX – SECTION 2
############################################
module "ec2_nginx" {
  source = "../../modules/ec2-nginx"

  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  alb_sg_id                  = module.alb.alb_sg_id
  ec2_instance_profile_name  = module.iam.ec2_instance_profile_name
}

############################################
# ALB LISTENER RULE FOR EC2
############################################
resource "aws_lb_listener_rule" "ec2_nginx" {
  listener_arn = module.alb.https_listener_arn
  priority     = 30

  condition {
    host_header {
      values = ["ec2.meghora.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = module.ec2_nginx.ec2_target_group_arn
  }
}

############################################
# ROUTE53 RECORD FOR EC2
############################################
resource "aws_route53_record" "ec2" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "ec2.meghora.com"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

# Root module
# We will call VPC, ALB, ECS, RDS modules from here
### 1. ECS with ALB, RDS and SecretsManager
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
#ALB Module
module "alb" {
  source = "../../modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  domain_name       = "example.com" # use free domain later

  tags = {
    Project = "Cloudzenia-Assignment"
    Env     = "dev"
  }
}

# Modules for IAM ,Secrets & RDS
module "secrets" {
  source = "../../modules/secrets"
}

module "iam" {
  source = "../../modules/iam"
}

module "rds" {
  source = "../../modules/rds"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_username        = "wpuser"
  db_password        = "WpPassword123!"
}

# module for ECS
module "ecs" {
  source = "../../modules/ecs"

  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  alb_sg_id            = module.alb.alb_sg_id
  http_listener_arn   = module.alb.http_listener_arn
  task_role_arn        = module.iam.ecs_task_role_arn
  db_endpoint          = module.rds.rds_endpoint
  db_secret_arn        = module.secrets.secret_arn
}

### 2. EC2 Instance with Domain Mapping and NGINX
#Attach EC2 TG to ALB Listener
module "ec2_nginx" {
  source = "../../modules/ec2-nginx"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.alb.alb_sg_id
}
# Add listener rule (reuse HTTP listener)
resource "aws_lb_listener_rule" "ec2_nginx" {
  listener_arn = module.alb.http_listener_arn
  priority     = 30

  condition {
    host_header {
      values = ["ec2.example.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = module.ec2_nginx.ec2_target_group_arn
  }
}

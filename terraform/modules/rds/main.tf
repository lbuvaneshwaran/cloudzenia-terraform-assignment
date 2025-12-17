#################################
# DB SUBNET GROUP
#################################
resource "aws_db_subnet_group" "this" {
  name       = "cloudzenia-db-subnet-${var.env}"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "cloudzenia-db-subnet-${var.env}"
  })
}

#################################
# RDS SECURITY GROUP
#################################
resource "aws_security_group" "rds_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#################################
# RDS INSTANCE
#################################
resource "aws_db_instance" "this" {
  identifier             = "cloudzenia-mysql-${var.env}"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible    = false
  backup_retention_period = 7
  skip_final_snapshot    = true
  db_name = "wordpress"

  tags = merge(var.tags, {
    Name = "cloudzenia-mysql-${var.env}"
  })
}

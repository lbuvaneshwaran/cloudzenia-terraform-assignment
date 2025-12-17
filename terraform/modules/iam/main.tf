#################################
# ECS TASK ROLE
#################################
resource "aws_iam_role" "ecs_task_role" {
  name = "cloudzenia-ecs-task-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

#################################
# ECS EXECUTION ROLE
#################################
resource "aws_iam_role" "ecs_execution_role" {
  name = "cloudzenia-ecs-execution-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#################################
# ECS TASK ROLE POLICY (SECRETS)
#################################
resource "aws_iam_role_policy" "ecs_task_policy" {
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.db_secret_arn
    }]
  })
}

#################################
# EC2 ROLE
#################################
resource "aws_iam_role" "ec2_role" {
  name = "cloudzenia-ec2-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

#################################
# EC2 OBSERVABILITY POLICY
#################################
resource "aws_iam_role_policy" "ec2_observability_policy" {
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ssm:SendCommand",
        "ssm:DescribeInstanceInformation"
      ]
      Resource = "*"
    }]
  })
}

#################################
# EC2 INSTANCE PROFILE
#################################
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "cloudzenia-ec2-profile-${var.env}"
  role = aws_iam_role.ec2_role.name
}

#################################
# ECS EXECUTION ROLE – SECRETS ACCESS
#################################
resource "aws_iam_role_policy" "ecs_execution_secrets_policy" {
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

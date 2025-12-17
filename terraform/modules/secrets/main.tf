resource "aws_secretsmanager_secret" "db_secret" {
  name = "cloudzenia-db-credentials-${var.env}"

  tags = {
    Project = "Cloudzenia-Assignment"
    Env     = var.env
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

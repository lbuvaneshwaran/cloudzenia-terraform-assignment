resource "aws_secretsmanager_secret" "db_secret" {
  name = "cloudzenia-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = "wpuser"
    password = "WpPassword123!"
  })
}

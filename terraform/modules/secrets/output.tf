output "secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_secret.arn
}

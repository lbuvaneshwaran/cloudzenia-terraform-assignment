#################################
# ENVIRONMENT
#################################
variable "env" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

#################################
# SECRETS MANAGER
#################################
variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret used by ECS tasks (WordPress DB credentials)"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "http_listener_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

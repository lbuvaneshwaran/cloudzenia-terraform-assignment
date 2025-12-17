variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "domain_name" {
  description = "Base domain name (example: meghora.com)"
  type        = string
}

variable "tags" {
  description = "Common tags for ALB resources"
  type        = map(string)
  default     = {}
}

variable "zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
}
variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

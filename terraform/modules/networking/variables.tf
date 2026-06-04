variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type        = string
  description = "Región AWS (debe coincidir con AZs us-east-1a/b, etc.)"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.42.0.0/16"
  description = "CIDR de la VPC del proyecto"
}

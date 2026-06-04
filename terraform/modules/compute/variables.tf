variable "project_name" { type = string }
variable "environment" { type = string }

variable "lab_role_arn" {
  type        = string
  description = "ARN de LabRole (AWS Academy); rol de ejecución de la Lambda"
}

variable "sensor_bucket_name" {
  type        = string
  description = "Bucket S3 donde la regla IoT guarda los JSON"
}

variable "mongodb_subnet_id" { type = string }
variable "mongodb_security_group_id" { type = string }
variable "lambda_subnet_ids" { type = list(string) }
variable "lambda_security_group_id" { type = string }

variable "mongodb_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "mongodb_username" {
  type    = string
  default = "iotadmin"
}

variable "mongodb_password" {
  type      = string
  sensitive = true
}

variable "mongodb_database" {
  type    = string
  default = "iot"
}

variable "mongodb_events_collection" {
  type    = string
  default = "sensor_events"
}

# --- ECS API (Fase 5) ---

variable "aws_region" {
  type        = string
  description = "Región AWS (env vars del contenedor y logs)"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Tabla DynamoDB de lecturas en tiempo real"
}

variable "vpc_id" {
  type = string
}

variable "ecs_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

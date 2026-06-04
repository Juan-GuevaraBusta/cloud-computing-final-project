variable "project_name" { type = string }
variable "environment" { type = string }
variable "lab_role_arn" { type = string }
variable "account_id" { type = string }
variable "region" { type = string }
variable "iot_endpoint" { type = string }
variable "root_ca_pem" { type = string }
variable "sensor_bucket_name" { type = string }
variable "sensor_table_name" { type = string }

variable "alert_publisher_lambda_arn" {
  type        = string
  description = "ARN de la Lambda que publica alertas en SQS (Fase 4)"
}

variable "alert_publisher_lambda_name" {
  type        = string
  description = "Nombre de la función Lambda publicadora de alertas"
}

variable "temperature_alert_threshold" {
  type        = number
  description = "Umbral °C para regla de alerta de temperatura"
  default     = 30
}

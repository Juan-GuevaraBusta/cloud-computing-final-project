variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "iot-edge"
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "lab"
}

variable "mongodb_username" {
  description = "Usuario administrador de MongoDB en EC2"
  type        = string
  default     = "iotadmin"
}

variable "mongodb_database" {
  description = "Base de datos MongoDB por defecto"
  type        = string
  default     = "iot"
}

variable "temperature_alert_threshold" {
  description = "Umbral de temperatura (°C) para la regla IoT 3 de alertas"
  type        = number
  default     = 30
}

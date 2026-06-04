resource "aws_dynamodb_table" "sensor_data" {
  name         = "SensorData-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  # Fase 1 decisión A: device_id + timestamp permiten últimos N eventos sin sobrescribir todo el historial.
  hash_key  = "device_id"
  range_key = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

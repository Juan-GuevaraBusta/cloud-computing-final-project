output "edge_gateway_thing_name" {
  value = aws_iot_thing.edge_gateway.name
}

output "temperature_alert_rule_arn" {
  description = "ARN de la regla IoT 3 (alertas de temperatura)"
  value       = aws_iot_topic_rule.temperature_alert.arn
}

output "temperature_alert_threshold" {
  value = var.temperature_alert_threshold
}

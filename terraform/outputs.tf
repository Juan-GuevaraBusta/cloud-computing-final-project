output "iot_endpoint" {
  description = "El endpoint de AWS IoT Core"
  value       = data.aws_iot_endpoint.iot_endpoint.endpoint_address
}

output "mongodb_private_ip" {
  description = "IP privada EC2 MongoDB (solo accesible desde la VPC)"
  value       = module.compute.mongodb_private_ip
}

output "lambda_s3_to_mongo_name" {
  description = "Nombre de la función Lambda histórico S3 → MongoDB"
  value       = module.compute.lambda_function_name
}

output "mongodb_uri" {
  description = "Copiar a .env local si tienes túnel/VPN; en AWS la usa Lambda"
  value       = module.compute.mongodb_uri
  sensitive   = true
}

output "alert_queue_url" {
  description = "Cola SQS de alertas de urgencia"
  value       = module.messaging.alert_queue_url
}

output "temperature_alert_threshold" {
  value = module.iot.temperature_alert_threshold
}

output "ecr_repository_url" {
  description = "Repositorio ECR de la API"
  value       = module.compute.ecr_repository_url
}

output "api_alb_dns_name" {
  description = "DNS público del ALB"
  value       = module.compute.api_alb_dns_name
}

output "api_swagger_url" {
  description = "Swagger UI en AWS"
  value       = module.compute.api_swagger_url
}

output "ecs_cluster_name" {
  value = module.compute.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.compute.ecs_service_name
}

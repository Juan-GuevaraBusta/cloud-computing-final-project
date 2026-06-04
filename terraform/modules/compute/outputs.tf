output "mongodb_private_ip" {
  description = "IP privada del EC2 con MongoDB (para .env local si hay túnel/VPN)"
  value       = aws_instance.mongodb.private_ip
}

output "lambda_function_name" {
  value = aws_lambda_function.s3_to_mongo.function_name
}

output "mongodb_uri" {
  description = "URI para API local; en AWS la usa la Lambda por variable de entorno"
  value       = local.mongodb_uri
  sensitive   = true
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR de la API"
  value       = aws_ecr_repository.api.repository_url
}

output "api_alb_dns_name" {
  description = "DNS del ALB (Swagger en http://<dns>/docs)"
  value       = aws_lb.api.dns_name
}

output "api_swagger_url" {
  value = "http://${aws_lb.api.dns_name}/docs"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.api.name
}

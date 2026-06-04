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

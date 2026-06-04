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

output "vpc_id" {
  value = aws_vpc.main.id
}

output "lambda_subnet_ids" {
  description = "Subnets donde se despliega Lambda (requiere 2 AZ)"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "mongodb_subnet_id" {
  description = "Subnet del servidor MongoDB (EC2)"
  value       = aws_subnet.public_a.id
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}

output "mongodb_security_group_id" {
  value = aws_security_group.mongodb.id
}

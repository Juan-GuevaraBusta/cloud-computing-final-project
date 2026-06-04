terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Módulo de Almacenamiento (S3)
module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  environment  = var.environment
}

# Módulo de Base de Datos (DynamoDB)
module "database" {
  source       = "./modules/database"
  project_name = var.project_name
  environment  = var.environment
}

# Módulo de mensajería y alertas (Fase 4) — antes de IoT regla 3
module "messaging" {
  source       = "./modules/messaging"
  project_name = var.project_name
  environment  = var.environment
  lab_role_arn = data.aws_iam_role.lab_role.arn
}

# Módulo de IoT Core
module "iot" {
  source       = "./modules/iot"
  project_name = var.project_name
  environment  = var.environment

  lab_role_arn   = data.aws_iam_role.lab_role.arn
  account_id     = data.aws_caller_identity.current.account_id
  region         = data.aws_region.current.name
  iot_endpoint   = data.aws_iot_endpoint.iot_endpoint.endpoint_address
  root_ca_pem    = data.http.root_ca.response_body

  sensor_bucket_name = module.storage.sensor_bucket_name
  sensor_table_name  = module.database.sensor_table_name

  alert_publisher_lambda_arn  = module.messaging.alert_publisher_lambda_arn
  alert_publisher_lambda_name = module.messaging.alert_publisher_lambda_name
  temperature_alert_threshold = var.temperature_alert_threshold

  depends_on = [module.messaging]
}

# Módulo de red (VPC, SG, endpoint S3) — Fase 2
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = data.aws_region.current.name
}

# Contraseña MongoDB (no commitear; Terraform la inyecta a EC2 y Lambda)
resource "random_password" "mongodb" {
  length  = 16
  special = false
}

# Módulo de cómputo: EC2 MongoDB + Lambda S3 → MongoDB en VPC — Fase 2
module "compute" {
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment

  sensor_bucket_name = module.storage.sensor_bucket_name

  mongodb_subnet_id           = module.networking.mongodb_subnet_id
  mongodb_security_group_id   = module.networking.mongodb_security_group_id
  lambda_subnet_ids           = module.networking.lambda_subnet_ids
  lambda_security_group_id    = module.networking.lambda_security_group_id

  mongodb_instance_type = "t3.micro"
  mongodb_username      = var.mongodb_username
  mongodb_password      = random_password.mongodb.result
  mongodb_database      = var.mongodb_database
  lab_role_arn          = data.aws_iam_role.lab_role.arn

  aws_region              = data.aws_region.current.name
  dynamodb_table_name     = module.database.sensor_table_name
  vpc_id                  = module.networking.vpc_id
  ecs_subnet_ids          = module.networking.ecs_subnet_ids
  ecs_security_group_id   = module.networking.ecs_security_group_id
  alb_security_group_id   = module.networking.alb_security_group_id

  depends_on = [module.storage, module.networking, module.database]
}

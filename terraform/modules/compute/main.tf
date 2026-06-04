# EC2 (MongoDB Docker) + Lambda S3 → MongoDB en VPC (Fase 2).

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Empaqueta la Lambda antes del zip (make lambda-build o local-exec).
resource "null_resource" "lambda_package" {
  triggers = {
    handler = filemd5("${path.module}/../../../lambda/s3_to_mongo/handler.py")
    reqs    = filemd5("${path.module}/../../../lambda/s3_to_mongo/requirements.txt")
  }

  provisioner "local-exec" {
    command     = "bash ${path.module}/../../../lambda/s3_to_mongo/build.sh"
    interpreter = ["bash", "-c"]
  }
}

data "archive_file" "s3_to_mongo_zip" {
  depends_on  = [null_resource.lambda_package]
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/s3_to_mongo/build"
  output_path = "${path.module}/../../../lambda/s3_to_mongo/deployment.zip"
}

locals {
  mongodb_uri = "mongodb://${var.mongodb_username}:${var.mongodb_password}@${aws_instance.mongodb.private_ip}:27017/${var.mongodb_database}?authSource=admin"
}

# --- EC2: MongoDB en Docker con autenticación ---

resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.mongodb_instance_type
  subnet_id              = var.mongodb_subnet_id
  vpc_security_group_ids = [var.mongodb_security_group_id]

  user_data = templatefile("${path.module}/user_data/mongodb.sh.tpl", {
    mongodb_username = var.mongodb_username
    mongodb_password = var.mongodb_password
    mongodb_database = var.mongodb_database
  })

  user_data_replace_on_change = true

  tags = {
    Name        = "${var.project_name}-mongodb-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# --- Lambda ---
# Learner Lab: no se puede usar iam:CreateRole; se reutiliza LabRole (como las reglas IoT).

resource "aws_lambda_function" "s3_to_mongo" {
  function_name = "${var.project_name}-s3-to-mongo-${var.environment}"
  role          = var.lab_role_arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  filename         = data.archive_file.s3_to_mongo_zip.output_path
  source_code_hash = data.archive_file.s3_to_mongo_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      MONGODB_URI        = local.mongodb_uri
      MONGODB_DB         = var.mongodb_database
      MONGODB_COLLECTION = var.mongodb_events_collection
    }
  }

  depends_on = [aws_instance.mongodb]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_mongo.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.sensor_bucket_name}"
}

resource "aws_s3_bucket_notification" "sensor_data_lambda" {
  bucket = var.sensor_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_mongo.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

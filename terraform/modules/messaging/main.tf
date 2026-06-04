# Fase 4: SQS + Lambdas de alerta (publicador IoT → cola → consumidor → CloudWatch).

# --- Empaquetado ---

resource "null_resource" "alert_publisher_package" {
  triggers = {
    handler = filemd5("${path.module}/../../../lambda/alert_publisher/handler.py")
  }
  provisioner "local-exec" {
    command     = "bash ${path.module}/../../../lambda/alert_publisher/build.sh"
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "alert_consumer_package" {
  triggers = {
    handler = filemd5("${path.module}/../../../lambda/alert_consumer/handler.py")
  }
  provisioner "local-exec" {
    command     = "bash ${path.module}/../../../lambda/alert_consumer/build.sh"
    interpreter = ["bash", "-c"]
  }
}

data "archive_file" "alert_publisher_zip" {
  depends_on  = [null_resource.alert_publisher_package]
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/alert_publisher/build"
  output_path = "${path.module}/../../../lambda/alert_publisher/deployment.zip"
}

data "archive_file" "alert_consumer_zip" {
  depends_on  = [null_resource.alert_consumer_package]
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/alert_consumer/build"
  output_path = "${path.module}/../../../lambda/alert_consumer/deployment.zip"
}

# --- SQS ---

resource "aws_sqs_queue" "alert_dlq" {
  name                      = "${var.project_name}-alert-dlq-${var.environment}"
  message_retention_seconds = 1209600

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "alerts" {
  name                       = "${var.project_name}-alerts-${var.environment}"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.alert_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# --- Lambdas (LabRole — Learner Lab) ---

resource "aws_lambda_function" "alert_publisher" {
  function_name = "${var.project_name}-alert-publisher-${var.environment}"
  role          = var.lab_role_arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 128

  filename         = data.archive_file.alert_publisher_zip.output_path
  source_code_hash = data.archive_file.alert_publisher_zip.output_base64sha256

  environment {
    variables = {
      ALERT_QUEUE_URL = aws_sqs_queue.alerts.url
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lambda_function" "alert_consumer" {
  function_name = "${var.project_name}-alert-consumer-${var.environment}"
  role          = var.lab_role_arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 128

  filename         = data.archive_file.alert_consumer_zip.output_path
  source_code_hash = data.archive_file.alert_consumer_zip.output_base64sha256

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_consumer" {
  event_source_arn = aws_sqs_queue.alerts.arn
  function_name    = aws_lambda_function.alert_consumer.arn
  batch_size       = 5
  enabled          = true
}

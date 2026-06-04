output "alert_publisher_lambda_arn" {
  value = aws_lambda_function.alert_publisher.arn
}

output "alert_publisher_lambda_name" {
  value = aws_lambda_function.alert_publisher.function_name
}

output "alert_consumer_lambda_name" {
  value = aws_lambda_function.alert_consumer.arn
}

output "alert_queue_url" {
  value = aws_sqs_queue.alerts.url
}

output "alert_queue_arn" {
  value = aws_sqs_queue.alerts.arn
}

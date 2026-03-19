output "api_endpoint" {
  description = "The endpoint URL for the API Gateway"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.visitor_counter.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.visitor_counter.arn
}

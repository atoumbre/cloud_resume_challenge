# --- DynamoDB Table for Visitor Count ---
resource "aws_dynamodb_table" "visitor_count" {
  name         = "${var.project_name}-visitor-count"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-visitor-count"
  }
}

# Initialize item to avoid error on first fetch in app.py
resource "aws_dynamodb_table_item" "init_visitor_count" {
  table_name = aws_dynamodb_table.visitor_count.name
  hash_key   = aws_dynamodb_table.visitor_count.hash_key

  item = jsonencode({
    "id" : { "S" : "visitor" },
    "count" : { "N" : "0" }
  })

  lifecycle {
    ignore_changes = [item]
  }
}

# --- Lambda Function ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend"
  output_path = "${path.module}/lambda.zip"
  excludes    = ["test_app.py", ".venv", "__pycache__", "test_app.py", ".pytest_cache"]
}

resource "aws_lambda_function" "visitor_counter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-counter-func"
  role             = aws_iam_role.lambda_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count.name
    }
  }
}

# --- IAM Role for Lambda ---
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamo_access_policy" {
  name        = "${var.project_name}-dynamo-access"
  description = "Allow Lambda to read/write visitor count table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:UpdateItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem"
      ]
      Resource = [aws_dynamodb_table.visitor_count.arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamo_access_policy.arn
}

# --- API Gateway (HTTP API v2) ---
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"

  integration_uri        = aws_lambda_function.visitor_counter.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "count_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /count"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gw_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

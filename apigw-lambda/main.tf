data "aws_caller_identity" "current" {}

data "archive_file" "zip" {
  type             = "zip"
  source_file      = "${path.module}/lambda/lambda_function.py"
  output_file_mode = "0666"
  output_path      = "/tmp/deployment_package.zip"
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "test-api"
  description = "This is my API for demonstration purposes"
}

# Message resource
resource "aws_api_gateway_resource" "message_resource" {
  path_part   = "message"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

# GET /message
resource "aws_api_gateway_method" "get_message" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.message_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_message_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.message_resource.id
  http_method             = aws_api_gateway_method.get_message.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# GET /message/item_id
resource "aws_api_gateway_method" "get_message_item" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.message_item_id_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_message_item_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.message_item_id_resource.id
  http_method             = aws_api_gateway_method.get_message_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}


# POST /message
resource "aws_api_gateway_method" "post_message" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.message_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_message_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.message_resource.id
  http_method             = aws_api_gateway_method.post_message.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# DELETE /message/{item_id}
resource "aws_api_gateway_resource" "message_item_id_resource" {
  path_part   = "{item_id}"
  parent_id   = aws_api_gateway_resource.message_resource.id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "delete_message_item" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.message_item_id_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_message_item_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.message_item_id_resource.id
  http_method             = aws_api_gateway_method.delete_message_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# PUT /message/{item_id}
resource "aws_api_gateway_method" "put_message_item" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.message_item_id_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "put_message_item_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.message_item_id_resource.id
  http_method             = aws_api_gateway_method.put_message_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# Deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = data.archive_file.zip.output_base64sha256
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_method.get_message,
    aws_api_gateway_method.post_message,
    aws_api_gateway_method.delete_message_item,
    aws_api_gateway_method.put_message_item,
    aws_api_gateway_integration.get_message_integration,
    aws_api_gateway_integration.post_message_integration,
    aws_api_gateway_integration.delete_message_item_integration,
    aws_api_gateway_integration.put_message_item_integration
  ]
}

resource "aws_api_gateway_stage" "demo_stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}

# DynamoDB
resource "aws_dynamodb_table" "items" {
  name           = "items"
  read_capacity  = "2"
  write_capacity = "5"
  hash_key       = "ItemID"

  attribute {
    name = "ItemID"
    type = "S"
  }
}

# Lambda Permissions
resource "aws_lambda_permission" "apigw_lambda_get_message" {
  statement_id  = "AllowExecutionFromAPIGatewayGetMessage"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:eu-west-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.get_message.http_method}${aws_api_gateway_resource.message_resource.path}"
}

resource "aws_lambda_permission" "apigw_lambda_get_message_item" {
  statement_id  = "AllowExecutionFromAPIGatewayGetMessageItem"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:eu-west-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.get_message_item.http_method}${aws_api_gateway_resource.message_item_id_resource.path}"
}

resource "aws_lambda_permission" "apigw_lambda_post_message" {
  statement_id  = "AllowExecutionFromAPIGatewayPostMessage"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:eu-west-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.post_message.http_method}${aws_api_gateway_resource.message_resource.path}"
}

resource "aws_lambda_permission" "apigw_lambda_delete_message_item" {
  statement_id  = "AllowExecutionFromAPIGatewayDeleteMessageItem"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:eu-west-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.delete_message_item.http_method}${aws_api_gateway_resource.message_item_id_resource.path}"
}

resource "aws_lambda_permission" "apigw_lambda_put_message_item" {
  statement_id  = "AllowExecutionFromAPIGatewayPutMessageItem"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:eu-west-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.put_message_item.http_method}${aws_api_gateway_resource.message_item_id_resource.path}"
}

# Lambda Function
resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  function_name    = "test-lambda"
  role             = aws_iam_role.role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.7"
  timeout          = 10

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.items.name
    }
  }
}

# IAM Role
resource "aws_iam_role" "role" {
  name = "myrole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}


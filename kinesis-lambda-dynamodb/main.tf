data "archive_file" "order_processor_package" {
  type             = "zip"
  source_file      = "${path.module}/lambda/order-processor/src/lambda_function.py"
  output_file_mode = "0666"
  output_path      = "/tmp/deployment_package.zip"
}

resource "aws_dynamodb_table" "orders" {
  name           = "orders"
  read_capacity  = "2"
  write_capacity = "5"
  hash_key       = "OrderID"

  attribute {
    name = "OrderID"
    type = "S"
  }
}

resource "aws_kinesis_stream" "orders_processor" {
  name = "orders_processor"
  shard_count = 1
  retention_period = 30

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "order_processor" {
  function_name    = "order_processor"
  filename         = "${path.module}/lambda/order-processor/deployment_package.zip"
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "python3.7"
  timeout          = 60
  memory_size      = 128
  source_code_hash = data.archive_file.order_processor_package.output_base64sha256
}

resource "aws_lambda_event_source_mapping" "order_processor_trigger" {
  event_source_arn              = aws_kinesis_stream.orders_processor.arn
  function_name                 = "order_processor"
  batch_size                    = 1
  starting_position             = "LATEST"
  enabled                       = true
  maximum_record_age_in_seconds = 604800
}

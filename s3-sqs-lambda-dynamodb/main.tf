# PROVIDERS
provider "aws" {
  region                      = "eu-west-1"
  access_key                  = "localstack"
  secret_key                  = "localstack"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    dynamodb   = "http://localhost:4566"
    s3         = "http://localhost:4566"
    iam        = "http://localhost:4566"
    lambda     = "http://localhost:4566"
    sqs        = "http://localhost:4566"
    sts        = "http://localhost:4566"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket = "my-bucket-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  queue {
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".json"
  }
}

resource "aws_sqs_queue" "queue" {
  name                      = "orders-queue"
  delay_seconds             = 10
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:orders-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.bucket.arn}" }
      }
    }
  ]
}
POLICY
}

data "archive_file" "zip" {
  type             = "zip"
  source_file      = "${path.module}/lambda_function.py"
  output_file_mode = "0666"
  output_path      = "/tmp/deployment_package.zip"
}

resource "aws_lambda_function" "order_processor" {
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  function_name    = "order-processor"
  role             = "fake_role"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.7"
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = aws_lambda_function.order_processor.arn
}

resource "aws_dynamodb_table" "orders" {
  name           = "orders-table"
  read_capacity  = "2"
  write_capacity = "5"
  hash_key       = "OrderID"

  attribute {
    name = "OrderID"
    type = "S"
  }
}


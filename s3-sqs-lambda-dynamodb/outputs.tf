output "s3_bucket" {
    value = aws_s3_bucket.bucket.id
}

output "sqs_queue" {
    value = aws_sqs_queue.queue.name
}

output "lambda_function" {
    value = aws_lambda_function.order_processor.id
}

output "dynamodb_table" {
    value = aws_dynamodb_table.orders.name
}


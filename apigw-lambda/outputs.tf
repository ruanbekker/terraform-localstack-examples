output "apigw_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "apigw_message_path" {
  value = aws_api_gateway_resource.message_resource.path
}

output "message_invoke_url" {
  value = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.api.id}/dev/_user_request_${aws_api_gateway_resource.message_resource.path}"
}

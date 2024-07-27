resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "example" {
  name        = "example-secret"
  description = "An example secret"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = random_password.password.result
}

output "secret_id" {
  value = aws_secretsmanager_secret.example.id
}

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
    dynamodb  = "http://localhost:4566"
    s3        = "http://localhost:4566"
  }
}

terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "terraform-state/terraform.tfstate"
    region                      = "eu-west-1"
    endpoint                    = "http://localhost:4566"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true 
    dynamodb_table              = "terraform-state-lock"
    dynamodb_endpoint           = "http://localhost:4566"
    encrypt                     = true
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "state_lock" {
  name           = "terraform-state-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# OUTPUTS
output "bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.state_lock.id
}

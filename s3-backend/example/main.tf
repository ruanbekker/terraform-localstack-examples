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
    sts       = "http://localhost:4566"
    iam       = "http://localhost:4566"
  }
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.60.0"
    }
  }
  
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "terraform-state/example/terraform.tfstate"
    region                      = "eu-west-1"
    access_key                  = "localstack"
    secret_key                  = "localstack"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true 
    dynamodb_table              = "terraform-state-lock"
    encrypt                     = false

    endpoints = {
      s3        = "http://localhost:4566"
      sts       = "http://localhost:4566"
      dynamodb  = "http://localhost:4566"
      iam       = "http://localhost:4566"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  bucket = "my-bucket-${data.aws_caller_identity.current.account_id}"

  tags   = {
    Name      = "my-bucket"
    Owner     = "devops"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# OUTPUTS
output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}


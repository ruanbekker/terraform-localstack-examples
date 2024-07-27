terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.60"
    }
    archive = {
      source = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region                      = "eu-west-1"
  access_key                  = "localstack"
  secret_key                  = "localstack"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    kinesis  = "http://localhost:4566"
    s3       = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

provider "archive" {}

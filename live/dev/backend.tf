terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "kea-dev-terraform-state"
    key            = "terraform.tfstate"
    dynamodb_table = "kea-dev-terraform-state-lock"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
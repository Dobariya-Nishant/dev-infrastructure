terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "cardstudio-terraform-state-bucket"
    key            = "cardstudio/dev/terraform.tfstate"
    dynamodb_table = "tf-backend-lock"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
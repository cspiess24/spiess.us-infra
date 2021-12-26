provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn = var.aws_assume_role
  }
}

terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {}

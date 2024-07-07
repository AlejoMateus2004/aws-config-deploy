terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.56.0"
    }
  }
}
# Provider
provider "aws" {
  profile = "admin-profile"
  region = "us-east-1"
}
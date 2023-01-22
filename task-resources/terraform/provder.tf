provider "aws" {
  region  = "us-east-1"
  shared_credentials_file = "$HOME/.aws/credentials"
}

terraform {
  required_providers {
    aws = {
      version = "~> 3.46"
    }
  }
backend "s3"{
  bucket = "upgrad-tfstate-file-capstone"
  key = "terraform.tfstate"
  region = "us-east-1"
}
}

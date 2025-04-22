terraform {
  backend "s3" {
    bucket = "bg-kar-terraform-state"
    key    = "terraform-new.tfstate"
    region = "us-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}
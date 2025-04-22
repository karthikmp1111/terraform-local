variable "aws_region" {
  default = "us-west-1"
}

variable "lambda_names" {
  type    = list(string)
  default = ["lambda1", "lambda2", "lambda3"]
}

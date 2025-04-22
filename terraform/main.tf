locals {
  lambda_files = {
    for name in var.lambda_names : name => "s3://bg-kar-terraform-state/lambda-packages/${name}/package.zip"
  }
}

# Convert lambda_names list to a map (key = lambda name, value = true)
locals {
  lambda_map = { for lambda in var.lambda_names : lambda => true }
}

# Fetch the S3 objects for the Lambda packages to track changes via their ETag
data "aws_s3_object" "lambda_package" {
  for_each = local.lambda_map  # Now using the map, not the list
  bucket   = "bg-kar-terraform-state"
  key      = "lambda-packages/${each.key}/package.zip"
}

resource "aws_lambda_function" "lambda" {
  for_each      = local.lambda_files
  function_name = each.key
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  # Directly specify the S3 bucket and key for the Lambda function package
  s3_bucket = "bg-kar-terraform-state"
  s3_key    = "lambda-packages/${each.key}/package.zip"

  # Use the ETag (source_code_hash) of the S3 object to detect changes
  source_code_hash = data.aws_s3_object.lambda_package[each.key].etag

  publish          = true

  environment {
    variables = {
      ENV = "dev"
      NEW_VARIABLE = "bg_lambda_test"
    }
  }

  lifecycle {
    ignore_changes = [environment, publish]  # Ignores changes in environment variables & publish flag
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "bg_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  lifecycle {
    ignore_changes = [name]  # Prevents unnecessary IAM role recreation
  }
}
########Test File###########
# resource "aws_s3_bucket_object" "test_file" {
#   bucket = "bg-kar-terraform-state"
#   key    = "karthik-file.txt"
#   content = "This is a test file for Terraform configuration"
# }

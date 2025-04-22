# #!/bin/bash

# # Define the S3 bucket and prefix
# BUCKET="bg-kar-terraform-state"
# S3_PREFIX="lambda-packages"
# LAMBDA_FOLDER="lambda-functions"

# # Function to check if the Lambda package exists in S3
# check_lambda_package_in_s3() {
#   local lambda_name=$1
#   echo "Checking if $lambda_name package exists in S3..."

#   # Check if the Lambda package already exists in S3
#   aws s3 ls s3://$BUCKET/$S3_PREFIX/$lambda_name/package.zip > /dev/null
#   if [ $? -ne 0 ]; then
#     echo "$lambda_name package not found in S3. Building and uploading..."
#     build_and_upload_lambda $lambda_name
#   else
#     echo "$lambda_name package found in S3. Skipping build & upload."
#   fi
# }

# # Function to build and upload Lambda package
# build_and_upload_lambda() {
#   local lambda_folder=$1
#   echo "Building Lambda package for $lambda_folder..."

#   # Check if the folder exists
#   if [ ! -d "$LAMBDA_FOLDER/$lambda_folder" ]; then
#     echo "Error: $LAMBDA_FOLDER/$lambda_folder directory does not exist!"
#     exit 1
#   fi

#   cd "$LAMBDA_FOLDER/$lambda_folder"

#   # Check if build.sh exists
#   if [ ! -f "build.sh" ]; then
#     echo "Error: build.sh script not found in $lambda_folder"
#     exit 1
#   fi

#   # Run build script to create package
#   echo "Running build.sh script for $lambda_folder..."
#   ./build.sh

#   # Debug: List files in the directory after build
#   echo "Listing files in $lambda_folder directory after build:"
#   ls -la

#   # Ensure the package.zip file is present
#   PACKAGE_PATH="$LAMBDA_FOLDER/$lambda_folder/package.zip"
#   echo "Looking for $PACKAGE_PATH..."

#   if [ ! -f "$PACKAGE_PATH" ]; then
#     echo "Error: $PACKAGE_PATH does not exist after build!"
#     exit 1
#   fi

#   # Upload the built package to S3
#   echo "Uploading $PACKAGE_PATH to S3..."
#   aws s3 cp "$PACKAGE_PATH" s3://$BUCKET/$S3_PREFIX/$lambda_folder/package.zip

#   # Go back to the root directory
#   cd ../../
# }

# # Main script execution

# # Check and upload Lambda1 package
# check_lambda_package_in_s3 "lambda1"

# # Check and upload Lambda2 package
# check_lambda_package_in_s3 "lambda2"

# # Check and upload Lambda3 package
# check_lambda_package_in_s3 "lambda3"

# # Applying Terraform changes
# echo "🚀 Applying Terraform changes..."

# # Ensure Terraform is initialized
# terraform init

# # Apply Terraform changes
# terraform apply -auto-approve




#!/bin/bash

# Define the S3 bucket and prefix
BUCKET="bg-kar-terraform-state"
S3_PREFIX="lambda-packages"
LAMBDA_FOLDER="lambda-functions"

# Function to check if the Lambda package exists in S3
check_lambda_package_in_s3() {
  local lambda_name=$1
  echo "Checking if $lambda_name package exists in S3..."

  # Check if the Lambda package already exists in S3
  aws s3 ls s3://$BUCKET/$S3_PREFIX/$lambda_name/package.zip > /dev/null
  if [ $? -ne 0 ]; then
    echo "$lambda_name package not found in S3. Building and uploading..."
    build_and_upload_lambda $lambda_name
  else
    echo "$lambda_name package found in S3. Skipping build & upload."
  fi
}

# Function to build and upload Lambda package
build_and_upload_lambda() {
  local lambda_folder=$1
  echo "Building Lambda package for $lambda_folder..."

  # Check if the folder exists
  if [ ! -d "$LAMBDA_FOLDER/$lambda_folder" ]; then
    echo "Error: $LAMBDA_FOLDER/$lambda_folder directory does not exist!"
    exit 1
  fi

  cd "$LAMBDA_FOLDER/$lambda_folder"

  # Check if build.sh exists
  if [ ! -f "build.sh" ]; then
    echo "Error: build.sh script not found in $lambda_folder"
    exit 1
  fi

  # Run build script to create package
  echo "Running build.sh script for $lambda_folder..."
  ./build.sh

  # Debug: List files in the directory after build
  echo "Listing files in $lambda_folder directory after build:"
  ls -la

  # Ensure the package.zip file is present
  PACKAGE_PATH="$LAMBDA_FOLDER/$lambda_folder/package.zip"
  echo "Looking for $PACKAGE_PATH..."

  if [ ! -f "$PACKAGE_PATH" ]; then
    echo "Error: $PACKAGE_PATH does not exist after build!"
    exit 1
  fi

  # Upload the built package to S3
  echo "Uploading $PACKAGE_PATH to S3..."
  aws s3 cp "$PACKAGE_PATH" s3://$BUCKET/$S3_PREFIX/$lambda_folder/package.zip

  # Go back to the root directory
  cd ../../
}

# Main script execution

# Check and upload Lambda1 package
check_lambda_package_in_s3 "lambda1"

# Check and upload Lambda2 package
check_lambda_package_in_s3 "lambda2"

# Check and upload Lambda3 package
check_lambda_package_in_s3 "lambda3"

# Applying Terraform changes
echo "🚀 Applying Terraform changes..."

# Navigate to the Terraform directory (relative to this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/terraform"

# Initialize and apply Terraform
terraform init
terraform apply -auto-approve

# Optional: Go back to original script directory if needed
cd "$SCRIPT_DIR"

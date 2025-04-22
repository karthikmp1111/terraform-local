# #!/bin/bash

# # Define the path to the Lambda functions folder
# LAMBDA_FOLDER="lambda-functions"

# # Define Lambda function names
# LAMBDA_FOLDERS=("lambda1" "lambda2" "lambda3")
# BUCKET="bg-kar-terraform-state"
# S3_PREFIX="lambda-packages"

# # Define the Terraform directory
# TERRAFORM_DIR="terraform"

# # Function to check if the Lambda package exists in S3
# check_s3_object() {
#   local lambda_folder=$1
#   aws s3 ls s3://$BUCKET/$S3_PREFIX/$lambda_folder/package.zip &> /dev/null
# }

# # Function to build and upload the Lambda package to S3
# build_and_upload_lambda() {
#   local lambda_folder=$1
#   echo "Building Lambda package for $lambda_folder..."

#   # Check if the folder exists
#   if [ ! -d "$LAMBDA_FOLDER/$lambda_folder" ]; then
#     echo "Error: $LAMBDA_FOLDER/$lambda_folder directory does not exist!"
#     exit 1
#   fi

#   cd "$LAMBDA_FOLDER/$lambda_folder"
#   if [ ! -f "build.sh" ]; then
#     echo "Error: build.sh script not found in $lambda_folder"
#     exit 1
#   fi

#   # Run build script to create package
#   ./build.sh

#   # Check if the package was created
#   if [ ! -f "$lambda_folder/package.zip" ]; then
#     echo "Error: $lambda_folder/package.zip does not exist after build!"
#     exit 1
#   fi

#   # Upload the built package to S3
#   echo "Uploading $lambda_folder/package.zip to S3..."
#   aws s3 cp "$lambda_folder/package.zip" s3://$BUCKET/$S3_PREFIX/$lambda_folder/package.zip
#   cd ../../
# }

# # Check each Lambda folder
# for lambda_folder in "${LAMBDA_FOLDERS[@]}"; do
#   echo "Checking if $lambda_folder package exists in S3..."

#   # Check if the package exists in S3
#   if check_s3_object $lambda_folder; then
#     echo "$lambda_folder package already exists in S3. Skipping build & upload."
#   else
#     echo "$lambda_folder package not found in S3. Building and uploading..."
#     build_and_upload_lambda $lambda_folder
#   fi
# done

# # Check if Terraform configuration files are present in the terraform directory
# if [ ! -f "$TERRAFORM_DIR/main.tf" ]; then
#   echo "Error: Terraform configuration file (main.tf) not found in $TERRAFORM_DIR!"
#   exit 1
# fi

# # Apply Terraform changes
# echo "🚀 Applying Terraform changes..."

# # Navigate to the terraform directory and apply changes
# cd $TERRAFORM_DIR
# terraform init
# terraform plan
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
  if [ ! -f "build.sh" ]; then
    echo "Error: build.sh script not found in $lambda_folder"
    exit 1
  fi

  # Run build script to create package
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

# Ensure Terraform is initialized
terraform init

# Apply Terraform changes
terraform apply -auto-approve

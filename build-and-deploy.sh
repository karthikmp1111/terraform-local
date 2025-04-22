# #!/bin/bash
# set -e

# LAMBDA_DIR="lambda-functions"
# S3_BUCKET="bg-kar-terraform-state"
# ZIP_PATH="lambda-packages"

# # Determine if HEAD~1 exists (i.e., there is more than one commit)
# if git rev-parse HEAD~1 >/dev/null 2>&1; then
#     CHANGED_LAMBDAS=$(git diff --name-only HEAD~1 HEAD | grep "^$LAMBDA_DIR/" | awk -F/ '{print $2}' | sort -u)
# else
#     echo "🟡 Only one commit found. Using HEAD diff instead."
#     CHANGED_LAMBDAS=$(git diff --name-only HEAD | grep "^$LAMBDA_DIR/" | awk -F/ '{print $2}' | sort -u)
# fi

# if [ -z "$CHANGED_LAMBDAS" ]; then
#     echo "✅ No Lambda code changes detected. Skipping build & upload."
#     exit 0
# fi

# echo "🔍 Detected changes in Lambda(s): $CHANGED_LAMBDAS"

# # Build and upload changed Lambda packages
# for lambda in $CHANGED_LAMBDAS; do
#     echo "🛠️ Building $lambda..."
#     (cd "$LAMBDA_DIR/$lambda" && ./build.sh)

#     echo "☁️ Uploading $lambda to S3..."
#     aws s3 cp "$LAMBDA_DIR/$lambda/package.zip" "s3://$S3_BUCKET/$ZIP_PATH/$lambda/package.zip"
# done

# # Deploy via Terraform
# echo "🚀 Applying Terraform changes..."
# cd terraform
# terraform init
# terraform apply -auto-approve



# #!/bin/bash
# set -e

# LAMBDA_DIR="lambda-functions"
# S3_BUCKET="bg-kar-terraform-state"
# ZIP_PATH="lambda-packages"

# # Determine if HEAD~1 exists (i.e., there is more than one commit)
# if git rev-parse HEAD~1 >/dev/null 2>&1; then
#     CHANGED_LAMBDAS=$(git diff --name-only HEAD~1 HEAD | grep "^$LAMBDA_DIR/" | awk -F/ '{print $2}' | sort -u)
# else
#     echo "🟡 Only one commit found. Using HEAD diff instead."
#     CHANGED_LAMBDAS=$(git diff --name-only HEAD | grep "^$LAMBDA_DIR/" | awk -F/ '{print $2}' | sort -u)
# fi

# if [ -z "$CHANGED_LAMBDAS" ]; then
#     echo "✅ No Lambda code changes detected. Skipping Lambda build & upload."
# else
#     echo "🔍 Detected changes in Lambda(s): $CHANGED_LAMBDAS"

#     # Build and upload changed Lambda packages
#     for lambda in $CHANGED_LAMBDAS; do
#         echo "🛠️ Building $lambda..."
#         (cd "$LAMBDA_DIR/$lambda" && ./build.sh)

#         echo "☁️ Uploading $lambda to S3..."
#         aws s3 cp "$LAMBDA_DIR/$lambda/package.zip" "s3://$S3_BUCKET/$ZIP_PATH/$lambda/package.zip"
#     done
# fi

# # Deploy via Terraform after Lambda packages are uploaded
# echo "🚀 Applying Terraform changes..."
# cd terraform
# terraform init
# terraform apply -auto-approve





#!/bin/bash

# Define the path to the Lambda functions folder
LAMBDA_FOLDER="lambda-functions"

# Define Lambda function names
LAMBDA_FOLDERS=("lambda1" "lambda2" "lambda3")
BUCKET="bg-kar-terraform-state"
S3_PREFIX="lambda-packages"

# Define the Terraform directory
TERRAFORM_DIR="terraform"

# Function to check if the Lambda package exists in S3
check_s3_object() {
  local lambda_folder=$1
  aws s3 ls s3://$BUCKET/$S3_PREFIX/$lambda_folder/package.zip &> /dev/null
}

# Function to build and upload the Lambda package to S3
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

  # Check if the package was created
  if [ ! -f "$lambda_folder/package.zip" ]; then
    echo "Error: $lambda_folder/package.zip does not exist after build!"
    exit 1
  fi

  # Upload the built package to S3
  echo "Uploading $lambda_folder/package.zip to S3..."
  aws s3 cp "$lambda_folder/package.zip" s3://$BUCKET/$S3_PREFIX/$lambda_folder/package.zip
  cd ../../
}

# Check each Lambda folder
for lambda_folder in "${LAMBDA_FOLDERS[@]}"; do
  echo "Checking if $lambda_folder package exists in S3..."

  # Check if the package exists in S3
  if check_s3_object $lambda_folder; then
    echo "$lambda_folder package already exists in S3. Skipping build & upload."
  else
    echo "$lambda_folder package not found in S3. Building and uploading..."
    build_and_upload_lambda $lambda_folder
  fi
done

# Check if Terraform configuration files are present in the terraform directory
if [ ! -f "$TERRAFORM_DIR/main.tf" ]; then
  echo "Error: Terraform configuration file (main.tf) not found in $TERRAFORM_DIR!"
  exit 1
fi

# Apply Terraform changes
echo "🚀 Applying Terraform changes..."

# Navigate to the terraform directory and apply changes
cd $TERRAFORM_DIR
terraform init
terraform plan
terraform apply -auto-approve



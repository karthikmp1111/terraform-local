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

# # Navigate to the Terraform directory (relative to this script)
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# cd "$SCRIPT_DIR/terraform"

# # Initialize and apply Terraform
# terraform init
# terraform apply -auto-approve

# # Optional: Go back to original script directory if needed
# cd "$SCRIPT_DIR"




# #!/bin/bash

# # Define the S3 bucket and prefix
# BUCKET="bg-kar-terraform-state"
# S3_PREFIX="lambda-packages"
# LAMBDA_FOLDER="lambda-functions"

# # Function to get the S3 ETag of a package
# get_s3_etag() {
#   local lambda_name=$1
#   aws s3api head-object --bucket "$BUCKET" --key "$S3_PREFIX/$lambda_name/package.zip" \
#     --query ETag --output text 2>/dev/null | tr -d '"'
# }

# # Function to calculate local package MD5
# get_local_md5() {
#   local file_path=$1
#   # On Linux/macOS: use md5sum or md5
#   if command -v md5sum &> /dev/null; then
#     md5sum "$file_path" | awk '{ print $1 }'
#   else
#     md5 -q "$file_path"
#   fi
# }

# # Function to build and upload Lambda package
# build_and_upload_lambda() {
#   local lambda_name=$1
#   local folder_path="$LAMBDA_FOLDER/$lambda_name"
#   local package_path="$folder_path/package.zip"

#   echo "🔧 Building Lambda package for $lambda_name..."

#   # Check if the folder exists
#   if [ ! -d "$folder_path" ]; then
#     echo "❌ Error: $folder_path does not exist!"
#     exit 1
#   fi

#   cd "$folder_path"

#   if [ ! -f "build.sh" ]; then
#     echo "❌ Error: build.sh not found in $lambda_name"
#     exit 1
#   fi

#   ./build.sh

#   if [ ! -f "package.zip" ]; then
#     echo "❌ Error: package.zip not created in $folder_path!"
#     exit 1
#   fi

#   echo "📦 Checking if S3 package needs updating..."

#   local local_md5
#   local_md5=$(get_local_md5 "package.zip")

#   local s3_etag
#   s3_etag=$(get_s3_etag "$lambda_name")

#   if [ "$local_md5" == "$s3_etag" ]; then
#     echo "✅ No changes in $lambda_name package. Skipping upload."
#   else
#     echo "⬆️ Changes detected. Uploading $lambda_name package to S3..."
#     aws s3 cp "package.zip" s3://$BUCKET/$S3_PREFIX/$lambda_name/package.zip
#   fi

#   cd ../../
# }

# # Main logic
# for lambda in lambda1 lambda2 lambda3; do
#   build_and_upload_lambda "$lambda"
# done

# # Terraform apply
# echo "🚀 Applying Terraform changes..."

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# cd "$SCRIPT_DIR/terraform"

# terraform init
# terraform apply -auto-approve

# cd "$SCRIPT_DIR"



#!/bin/bash

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Config
BUCKET="bg-kar-terraform-state"
S3_PREFIX="lambda-packages"
LAMBDA_FOLDER="lambda-functions"
HASH_STORE=".lambda_hashes"

mkdir -p "$HASH_STORE"

# Function to compute a hash of the Lambda source files
compute_source_hash() {
  local folder_path=$1
  find "$folder_path" -type f \( -name "*.py" -o -name "requirements.txt" \) -exec md5sum {} \; | sort | md5sum | awk '{print $1}'
}

# Function to build and upload Lambda package if changed
build_and_upload_lambda() {
  local lambda_name=$1
  local folder_path="$SCRIPT_DIR/$LAMBDA_FOLDER/$lambda_name"
  local package_path="$folder_path/package.zip"
  local hash_file="$HASH_STORE/$lambda_name.hash"

  echo "🔍 Checking for changes in $lambda_name..."

  if [ ! -d "$folder_path" ]; then
    echo "❌ $folder_path not found."
    exit 1
  fi

  # Compute current hash of source files
  local current_hash
  current_hash=$(compute_source_hash "$folder_path")

  # Load previous hash
  local previous_hash=""
  if [ -f "$hash_file" ]; then
    previous_hash=$(cat "$hash_file")
  fi

  # If no change, skip build & upload
  if [ "$current_hash" == "$previous_hash" ]; then
    echo "✅ No changes detected in $lambda_name. Skipping build & upload."
    return
  fi

  echo "🔧 Changes detected in $lambda_name. Running build and uploading..."

  cd "$folder_path"

  if [ ! -f "build.sh" ]; then
    echo "❌ Error: build.sh not found in $lambda_name"
    exit 1
  fi

  ./build.sh

  if [ ! -f "package.zip" ]; then
    echo "❌ Error: package.zip not created!"
    exit 1
  fi

  # Upload the package to S3
  aws s3 cp "package.zip" s3://$BUCKET/$S3_PREFIX/$lambda_name/package.zip

  # Save the current hash for future comparison
  echo "$current_hash" > "$SCRIPT_DIR/$hash_file"

  cd "$SCRIPT_DIR"
}

# Process each lambda function
for lambda in lambda1 lambda2 lambda3; do
  build_and_upload_lambda "$lambda"
done

# Apply Terraform changes
echo "🚀 Applying Terraform changes..."
cd "$SCRIPT_DIR/terraform"
terraform init
terraform apply -auto-approve
cd "$SCRIPT_DIR"

#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUCKET="bg-kar-terraform-state"
S3_PREFIX="lambda-packages"
LAMBDA_FOLDER="lambda-functions"
HASH_STORE=".lambda_hashes"

mkdir -p "$HASH_STORE"

compute_source_hash() {
  local folder_path=$1
  find "$folder_path" -type f \( -name "*.py" -o -name "requirements.txt" -o -name "*.txt" -o -name "*.yaml" -o -name "*.yml" \) -exec md5sum {} \; | sort | md5sum | awk '{print $1}'
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
# terraform destroy -auto-approve
cd "$SCRIPT_DIR"

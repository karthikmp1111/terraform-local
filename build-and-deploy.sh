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
set -e

LAMBDA_DIR="lambda-functions"
S3_BUCKET="bg-kar-terraform-state"
ZIP_PATH="lambda-packages"

# Function to check if the Lambda package exists in S3
check_lambda_package_in_s3() {
  local lambda_name=$1
  aws s3 ls "s3://$S3_BUCKET/$ZIP_PATH/$lambda_name/package.zip" > /dev/null 2>&1
  return $?
}

# Get list of changed Lambda directories using git diff (compare with last commit)
if git rev-parse HEAD~1 >/dev/null 2>&1; then
    CHANGED_LAMBDAS=$(git diff --name-only HEAD~1 HEAD | grep "^$LAMBDA_DIR/" | awk -F/ '{print $2}' | sort -u)
else
    echo "🟡 Only one commit found. Using HEAD diff instead."
    CHANGED_LAMBDAS=$(git diff --name-only HEAD | grep "^$LAMBDA_DIR/" | awk -F/ '{print $2}' | sort -u)
fi

if [ -z "$CHANGED_LAMBDAS" ]; then
    echo "✅ No Lambda code changes detected. Skipping build & upload."
else
    echo "🔍 Detected changes in Lambda(s): $CHANGED_LAMBDAS"
fi

# Loop through Lambda functions and handle build/upload
for lambda in $CHANGED_LAMBDAS; do
    echo "🛠️ Building $lambda..."

    # Check if the Lambda package exists in S3
    if ! check_lambda_package_in_s3 "$lambda"; then
        echo "⚠️ Lambda package for $lambda not found in S3. Building and uploading."
        (cd "$LAMBDA_DIR/$lambda" && ./build.sh)
        echo "☁️ Uploading $lambda to S3..."
        aws s3 cp "$LAMBDA_DIR/$lambda/package.zip" "s3://$S3_BUCKET/$ZIP_PATH/$lambda/package.zip"
    else
        echo "✅ $lambda package already exists in S3. Skipping upload."
    fi
done

# Apply Terraform changes
echo "🚀 Applying Terraform changes..."
cd terraform
terraform init
terraform apply -auto-approve

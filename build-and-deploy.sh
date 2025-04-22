#!/bin/bash
set -e

LAMBDA_DIR="lambda-functions"
S3_BUCKET="bg-kar-terraform-state"
ZIP_PATH="lambda-packages"

# Determine if HEAD~1 exists (i.e., there is more than one commit)
if git rev-parse HEAD~1 >/dev/null 2>&1; then
    CHANGED_LAMBDAS=$(git diff --name-only HEAD~1 HEAD | grep "^$LAMBDA_DIR/" | awk -F/ '{print $2}' | sort -u)
else
    echo "🟡 Only one commit found. Using HEAD diff instead."
    CHANGED_LAMBDAS=$(git diff --name-only HEAD | grep "^$LAMBDA_DIR/" | awk -F/ '{print $2}' | sort -u)
fi

if [ -z "$CHANGED_LAMBDAS" ]; then
    echo "✅ No Lambda code changes detected. Skipping build & upload."
    exit 0
fi

echo "🔍 Detected changes in Lambda(s): $CHANGED_LAMBDAS"

# Build and upload changed Lambda packages
for lambda in $CHANGED_LAMBDAS; do
    echo "🛠️ Building $lambda..."
    (cd "$LAMBDA_DIR/$lambda" && ./build.sh)

    echo "☁️ Uploading $lambda to S3..."
    aws s3 cp "$LAMBDA_DIR/$lambda/package.zip" "s3://$S3_BUCKET/$ZIP_PATH/$lambda/package.zip"
done

# Deploy via Terraform
echo "🚀 Applying Terraform changes..."
cd terraform
terraform init
terraform apply -auto-approve

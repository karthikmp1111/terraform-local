#!/bin/bash
set -e  # Exit on any error

LAMBDA_NAME=$(basename "$PWD")

echo "Building $LAMBDA_NAME..."

# Move to the correct directory (if needed)
cd "$(dirname "$0")"

# Verify requirements.txt exists
if [[ ! -f "requirements.txt" ]]; then
    echo "❌ ERROR: requirements.txt not found in $(pwd)"
    exit 1
fi

# Install dependencies
pip install -r requirements.txt -t .

# Create zip package
zip -r package.zip . -x "build.sh" "*.pyc" "__pycache__/*"

echo "✅ Build completed for $LAMBDA_NAME"

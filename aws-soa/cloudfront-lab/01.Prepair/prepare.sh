#!/bin/bash

# Script to deploy CloudFormation stack and upload files to S3 bucket

# Exit on any error
set -e

# Variables
STACK_NAME="soa-s3-cloudfront-lab"
TEMPLATE_FILE="s3-cloudformation-template.yaml"
BUCKET_POSTFIX="$1"
REGION="us-east-1"  # Change to your desired AWS region
RESOURCES_DIR="resources"

# Function to display usage
usage() {
    echo "Usage: $0 <bucket-postfix>"
    echo "Example: $0 001"
    exit 1
}

# Check if bucket postfix is provided
if [ -z "$BUCKET_POSTFIX" ]; then
    echo "Error: Bucket postfix is required."
    usage
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file $TEMPLATE_FILE not found."
    exit 1
fi

# Check if resources directory exists
if [ ! -d "$RESOURCES_DIR" ]; then
    echo "Error: Resources directory $RESOURCES_DIR not found."
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed."
    exit 1
fi

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack: $STACK_NAME"
aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --parameter-overrides BucketPostfix="$BUCKET_POSTFIX" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION" \
    --no-fail-on-empty-changeset

# Wait for stack to complete
echo "Waiting for stack creation to complete..."
aws cloudformation wait stack-create-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

# Get bucket name from stack outputs
echo "Retrieving bucket name from stack outputs..."
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" \
    --output text)

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: Failed to retrieve bucket name."
    exit 1
fi

echo "Bucket name: $BUCKET_NAME"

# Upload files to S3
echo "Uploading files to S3 bucket: $BUCKET_NAME"
cd "$RESOURCES_DIR"

# Upload individual files
for file in autodeletefunction-new.zip awsclilayer-new.zip demosite.zip demovideo.zip filedeployfunction-new.zip; do
    if [ -f "$file" ]; then
        echo "Uploading $file..."
        aws s3 cp "$file" "s3://$BUCKET_NAME/$file" --region "$REGION"
    else
        echo "Warning: $file not found, skipping."
    fi
done

# Upload files in function directory
if [ -d "function" ]; then
    cd function
    for file in echo.zip fle.zip getplayurl.zip getsignedcookie.zip login.zip logout.zip sessionvalue.zip teststaleobject.zip; do
        if [ -f "$file" ]; then
            echo "Uploading function/$file..."
            aws s3 cp "$file" "s3://$BUCKET_NAME/function/$file" --region "$REGION"
        else
            echo "Warning: function/$file not found, skipping."
        fi
    done
    cd -
else
    echo "Warning: function directory not found, skipping function files."
fi

echo "Deployment and upload completed successfully!"
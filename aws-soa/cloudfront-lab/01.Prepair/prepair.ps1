# Script to deploy CloudFormation stack and upload files to S3 bucket
param(
    [Parameter(Mandatory=$true)]
    [string]$BucketPostfix
)

# Exit on any error
$ErrorActionPreference = "Stop"

# Variables
$STACK_NAME = "soa-s3-cloudfront-lab"
$TEMPLATE_FILE = "s3-cloudformation-template.yaml"
$REGION = "us-east-1"  # Change to your desired AWS region
$RESOURCES_DIR = "resources"

# Function to display usage
function Show-Usage {
    Write-Host "Usage: .\deploy.ps1 -BucketPostfix <bucket-postfix>"
    Write-Host "Example: .\deploy.ps1 -BucketPostfix 001"
    exit 1
}

# Check if template file exists
if (-not (Test-Path $TEMPLATE_FILE)) {
    Write-Host "Error: Template file $TEMPLATE_FILE not found." -ForegroundColor Red
    exit 1
}

# Check if resources directory exists
if (-not (Test-Path $RESOURCES_DIR -PathType Container)) {
    Write-Host "Error: Resources directory $RESOURCES_DIR not found." -ForegroundColor Red
    exit 1
}

# Check if AWS CLI is installed
try {
    aws --version | Out-Null
} catch {
    Write-Host "Error: AWS CLI is not installed." -ForegroundColor Red
    exit 1
}

# Deploy CloudFormation stack
Write-Host "Deploying CloudFormation stack: $STACK_NAME" -ForegroundColor Green
aws cloudformation deploy `
    --stack-name $STACK_NAME `
    --template-file $TEMPLATE_FILE `
    --parameter-overrides BucketPostfix=$BucketPostfix `
    --capabilities CAPABILITY_NAMED_IAM `
    --region $REGION `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: CloudFormation deployment failed." -ForegroundColor Red
    exit 1
}

# Wait for stack to complete
Write-Host "Waiting for stack creation to complete..." -ForegroundColor Yellow
aws cloudformation wait stack-create-complete `
    --stack-name $STACK_NAME `
    --region $REGION

# Get bucket name from stack outputs
Write-Host "Retrieving bucket name from stack outputs..." -ForegroundColor Yellow
$BUCKET_NAME = aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --region $REGION `
    --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" `
    --output text

if ([string]::IsNullOrEmpty($BUCKET_NAME)) {
    Write-Host "Error: Failed to retrieve bucket name." -ForegroundColor Red
    exit 1
}

Write-Host "Bucket name: $BUCKET_NAME" -ForegroundColor Green

# Upload files to S3
Write-Host "Uploading files to S3 bucket: $BUCKET_NAME" -ForegroundColor Green
Push-Location $RESOURCES_DIR

# Upload individual files
$files = @("autodeletefunction-new.zip", "awsclilayer-new.zip", "demosite.zip", "demovideo.zip", "filedeployfunction-new.zip")

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Uploading $file..." -ForegroundColor Cyan
        aws s3 cp $file "s3://$BUCKET_NAME/$file" --region $REGION
    } else {
        Write-Host "Warning: $file not found, skipping." -ForegroundColor Yellow
    }
}

# Upload files in function directory
if (Test-Path "function" -PathType Container) {
    Push-Location "function"
    $functionFiles = @("echo.zip", "fle.zip", "getplayurl.zip", "getsignedcookie.zip", "login.zip", "logout.zip", "sessionvalue.zip", "teststaleobject.zip")
    
    foreach ($file in $functionFiles) {
        if (Test-Path $file) {
            Write-Host "Uploading function/$file..." -ForegroundColor Cyan
            aws s3 cp $file "s3://$BUCKET_NAME/function/$file" --region $REGION
        } else {
            Write-Host "Warning: function/$file not found, skipping." -ForegroundColor Yellow
        }
    }
    Pop-Location
} else {
    Write-Host "Warning: function directory not found, skipping function files." -ForegroundColor Yellow
}

Pop-Location
Write-Host "Deployment and upload completed successfully!" -ForegroundColor Green
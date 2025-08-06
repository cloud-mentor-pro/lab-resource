@echo off
setlocal enabledelayedexpansion

REM Script to deploy CloudFormation stack and upload files to S3 bucket

REM Variables
set STACK_NAME=soa-s3-cloudfront-lab
set TEMPLATE_FILE=s3-cloudformation-template.yaml
set BUCKET_POSTFIX=%1
set REGION=us-east-1
set RESOURCES_DIR=resources

REM Function to display usage
if "%BUCKET_POSTFIX%"=="" (
    echo Error: Bucket postfix is required.
    echo Usage: %0 ^<bucket-postfix^>
    echo Example: %0 001
    exit /b 1
)

REM Check if template file exists
if not exist "%TEMPLATE_FILE%" (
    echo Error: Template file %TEMPLATE_FILE% not found.
    exit /b 1
)

REM Check if resources directory exists
if not exist "%RESOURCES_DIR%" (
    echo Error: Resources directory %RESOURCES_DIR% not found.
    exit /b 1
)

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if errorlevel 1 (
    echo Error: AWS CLI is not installed.
    exit /b 1
)

REM Deploy CloudFormation stack
echo Deploying CloudFormation stack: %STACK_NAME%
aws cloudformation deploy ^
    --stack-name %STACK_NAME% ^
    --template-file %TEMPLATE_FILE% ^
    --parameter-overrides BucketPostfix=%BUCKET_POSTFIX% ^
    --capabilities CAPABILITY_NAMED_IAM ^
    --region %REGION% ^
    --no-fail-on-empty-changeset

if errorlevel 1 (
    echo Error: CloudFormation deployment failed.
    exit /b 1
)

REM Wait for stack to complete
echo Waiting for stack creation to complete...
aws cloudformation wait stack-create-complete ^
    --stack-name %STACK_NAME% ^
    --region %REGION%

REM Get bucket name from stack outputs
echo Retrieving bucket name from stack outputs...
for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --region %REGION% --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text') do set BUCKET_NAME=%%i

if "%BUCKET_NAME%"=="" (
    echo Error: Failed to retrieve bucket name.
    exit /b 1
)

echo Bucket name: %BUCKET_NAME%

REM Upload files to S3
echo Uploading files to S3 bucket: %BUCKET_NAME%
cd %RESOURCES_DIR%

REM Upload individual files
set files=autodeletefunction-new.zip awsclilayer-new.zip demosite.zip demovideo.zip filedeployfunction-new.zip

for %%f in (%files%) do (
    if exist "%%f" (
        echo Uploading %%f...
        aws s3 cp "%%f" "s3://%BUCKET_NAME%/%%f" --region %REGION%
    ) else (
        echo Warning: %%f not found, skipping.
    )
)

REM Upload files in function directory
if exist "function" (
    cd function
    set functionFiles=echo.zip fle.zip getplayurl.zip getsignedcookie.zip login.zip logout.zip sessionvalue.zip teststaleobject.zip
    
    for %%f in (!functionFiles!) do (
        if exist "%%f" (
            echo Uploading function/%%f...
            aws s3 cp "%%f" "s3://%BUCKET_NAME%/function/%%f" --region %REGION%
        ) else (
            echo Warning: function/%%f not found, skipping.
        )
    )
    cd ..
) else (
    echo Warning: function directory not found, skipping function files.
)

cd ..
echo Deployment and upload completed successfully!
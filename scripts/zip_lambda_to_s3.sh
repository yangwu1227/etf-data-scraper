#!/bin/bash

read -p "Enter the absolute path to the lambda function directory including the lambda_function.py and package_and_zip.sh files: " lambda_path

if [ ! -d "$lambda_path" ]; then
  echo "Error: Specified directory does not exist"
  exit 1
fi

# Validate the presence of required files
if [ ! -f "$lambda_path/lambda_function.py" ] || [ ! -f "$lambda_path/package_and_zip.sh" ]; then
  echo "Error: Directory must contain lambda_function.py and package_and_zip.sh"
  exit 1
fi

read -p "Enter the name of the S3 bucket to upload the Lambda function code: " s3_bucket_name
read -p "Enter the AWS profile name to use for uploading the Lambda function code: " aws_profile

# Run the package_and_zip.sh script to create the zip file
cd $lambda_path 
if ! ./package_and_zip.sh; then
  echo "Error: Failed to package Lambda function using package_and_zip.sh"
  exit 1
fi

# Upload the zip file to the S3 bucket
aws s3 cp lambda_function.zip s3://"$s3_bucket_name" --profile "$aws_profile"

rm lambda_function.zip

echo "Lambda function code uploaded to S3 bucket: $s3_bucket_name"

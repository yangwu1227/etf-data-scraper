#!/bin/bash

read -p "Enter the absolute path to the lambda function file: " lambda_file_path

# Check if the file exists
if [ ! -f "$lambda_file_path" ]; then
  echo "File does not exist"
  exit 1
fi

read -p "Enter the name of the S3 bucket to upload the Lambda function code: " s3_bucket_name

# Zip to the current directory where the script is executed
zip -r lambda_function.zip "$lambda_file_path"

aws s3 cp lambda_function.zip s3://$s3_bucket_name

# Remove the zip file after uploading to S3
rm lambda_function.zip

echo "Lambda function code uploaded to S3 bucket: $s3_bucket_name"

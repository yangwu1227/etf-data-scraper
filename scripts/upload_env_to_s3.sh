#!/bin/bash

read -p "Enter the absolute path to the .env file: " env_file_path

# Check if the file exists
if [ ! -f "$env_file_path" ]; then
  echo "File does not exist"
  exit 1
fi

read -p "Enter the name of the S3 bucket to upload the .env file: " s3_bucket_name
read -p "Enter the AWS profile name to use for uploading the .env file: " aws_profile

aws s3 cp $env_file_path s3://"$s3_bucket_name"/vars.env --profile "$aws_profile"

echo ".env file uploaded to S3 bucket: "$s3_bucket_name""

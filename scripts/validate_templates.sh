#!/bin/bash

read -p "Enter the absolute path to the directory containing CloudFormation template YAML files: " directory

# Check if the directory exists
if [ ! -d "$directory" ]; then
  echo "Directory does not exist"
  exit 1
fi

for file in "$directory"/*.yaml; do
  if [ -f "$file" ]; then
    echo "Validating template: $file"
    
    # Stack: https://stackoverflow.com/questions/818255/what-does-21-mean
    validation_output=$(aws cloudformation validate-template --template-body file://"$file" 2>&1)
    
    # Check if the validation was successful
    if [ $? -eq 0 ]; then
      echo "Success: $file is valid"
    else
      echo "Failure: $file is invalid"
      echo "Error: $validation_output"
      exit 1
    fi
  else
    echo "No YAML files found in the directory"
    exit 1
  fi
done

echo "All templates validated successfully"

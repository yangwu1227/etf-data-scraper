#!/bin/bash

# Get the current working directory
cwd=$(pwd)

# Install dependencies into a "package" directory within cwd
pip install --target "$cwd/package" -r requirements.txt
cd "$cwd/package" || exit

# Create a zip archive containing the contents of the package directory
zip -r "$cwd/lambda_function.zip" .

# Add lambda_function.py to the zip file
cd "$cwd" || exit
zip lambda_function.zip lambda_function.py

# Clean up
rm -rf "$cwd/package"

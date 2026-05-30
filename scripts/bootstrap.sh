#!/bin/bash
set -e

echo "Initializing bootstrap..."
cd bootstrap
terraform init
terraform apply -auto-approve

echo "Bootstrap complete!"
echo "S3 buckets and DynamoDB tables created."
echo "You can now run: make up-security"
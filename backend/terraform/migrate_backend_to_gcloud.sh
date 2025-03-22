#!/bin/bash

set -e

PROJECT_ID=$(jq -r '.project_id' variables.json 2>/dev/null)

if [ "$PROJECT_ID" == "null" ]; then
    PROJECT_ID=""
fi

if [ -z "$PROJECT_ID" ]; then
    echo "Project ID is not defined. Please enter your Google Cloud Project ID:"
    read PROJECT_ID
    jq --arg pid "$PROJECT_ID" '.project_id = $pid' variables.json > tmp.$$.json && mv tmp.$$.json variables.json
fi

terraform init -reconfigure
BUCKET_PREFIX=$(terraform output -raw google_cloud_state_bucket)

# Check if the bucket already exists in GCP and import if yes
if gsutil ls -p $PROJECT_ID gs://$BUCKET_PREFIX-bucket-tfstate 2>/dev/null; then
    echo "Bucket already exists. Importing it to Terraform."
    terraform import google_storage_bucket.default $BUCKET_PREFIX-bucket-tfstate
else
    echo "Bucket does not exist. It will be created."
fi

# Run terraform apply with targeting
terraform apply -auto-approve -target=random_id.bucket_prefix -target=google_storage_bucket.default

# Fetch the updated bucket name
UPDATED_BUCKET_NAME=$(terraform output -raw google_cloud_state_bucket)

# Update variables.json file
jq --arg bucket "$UPDATED_BUCKET_NAME" '.tfstate_bucket_url = $bucket' variables.json > tmp.$$.json && mv tmp.$$.json variables.json

echo "To finalize setup:"
echo "1. Uncomment the backend configuration in your 'terraform-backend.tf'."
echo "2. Update the 'bucket' value in the backend configuration with the new bucket name (saved in variables.json)"
echo "This needs to be done since terraform doesn't support variables in backend configuration."
echo "3. Initialize your Terraform setup with 'terraform init -reconfigure' to migrate the state to the new backend."
echo "4. Execute 'terraform apply' to confirm all configurations are correct."

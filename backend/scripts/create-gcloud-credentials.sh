#!/bin/bash
# This is a script to create a Google Cloud service account with the necessary roles and download the key file.

source "$(dirname "$0")/utils.sh"
set -e

# Check if gcloud is installed
if ! command -v gcloud > /dev/null 2>&1; then
	echo "Google Cloud SDK is not installed. Please install it first."
	exit 1
fi

# Get input from the user
DEFAULT_KEY_FILE_NAME="credentials.json"
create_separator
printf "Enter your Google Cloud project ID: "
read PROJECT_ID
printf "Enter the name for your service account: "
read SERVICE_ACCOUNT_NAME
printf "Enter a display name for your service account: "
read DISPLAY_NAME
printf "Enter the path and filename to save your service account key (e.g., /path/to/key.json): (default: $DEFAULT_KEY_FILE_NAME) "
read KEY_FILE_NAME
if [ -z "$KEY_FILE_NAME" ]; then
	KEY_FILE_NAME=$DEFAULT_KEY_FILE_NAME
fi
create_separator

# Set the project
gcloud config set project "$PROJECT_ID"

# Check if the service account already exists
EXISTING_ACCOUNT=$(gcloud iam service-accounts list --filter="email=${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --format="value(email)")

if [ -n "$EXISTING_ACCOUNT" ]; then
	echo "Service account $SERVICE_ACCOUNT_NAME already exists."
else
	# Create the service account
	gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
		--display-name="$DISPLAY_NAME" \
		--project="$PROJECT_ID"

	echo "Service account $SERVICE_ACCOUNT_NAME created successfully."
fi
create_separator

# Add necessary role
ROLE="roles/owner"

# Check if the service account has the necessary roles
EXISTING_ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --format="value(bindings.members)" --filter="bindings.members:serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com")
if [ -z "$EXISTING_ROLES" ]; then
	gcloud projects add-iam-policy-binding "$PROJECT_ID" \
		--member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
		--role="$ROLE" >/dev/null
	echo "Assigned $ROLE to $SERVICE_ACCOUNT_NAME."
else
	echo "Service account $SERVICE_ACCOUNT_NAME already has the necessary roles."
fi
create_separator

# Check if the key file already exists
if [ -f "$KEY_FILE_NAME" ]; then
	echo "Key file already exists at $KEY_FILE_NAME. Skipping key creation."
else
	# Create and download the key for the service account
	gcloud iam service-accounts keys create "$KEY_FILE_NAME" \
		--iam-account "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
		--project="$PROJECT_ID"

	echo "Service account key downloaded successfully to $KEY_FILE_NAME."
fi
create_separator

echo "Script completed successfully."

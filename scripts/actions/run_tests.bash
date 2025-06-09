#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
source "$SCRIPT_DIR/../utils/print.bash"

# Script parameters 
TARGET_ENV="${1:-}"

# Validation 
if [[ -z "$TARGET_ENV" || ("$TARGET_ENV" != "local" && "$TARGET_ENV" != "aws") ]]; then
    pretty_error "Invalid target environment. Usage: $0 <local|aws>"
    exit 1
fi

gen_separator '='
pretty_info "Starting API tests for environment: ${bold}${TARGET_ENV}${nc}"
gen_separator '='

# Setup Test Environment 
TEST_DIR="$PROJECT_ROOT/backend/tests"
cd "$TEST_DIR"

pretty_info "Setting up Python virtual environment and installing dependencies..."
if [[ ! -d ".venv" ]]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install -r requirements.txt > /dev/null
pretty_success "Dependencies are up to date."

# Configure for Target Environment 
if [[ "$TARGET_ENV" == "local" ]]; then
    pretty_info "Configuring for local Docker Compose environment..."
    
    # Ensure .env file exists
    if [[ ! -f "$PROJECT_ROOT/backend/.env" ]]; then
        pretty_warn "backend/.env file not found. Copying from template."
        cp "$PROJECT_ROOT/backend/.env.template" "$PROJECT_ROOT/backend/.env"
    fi

    # Load ADMIN_SECRET_KEY from .env file
    export ADMIN_SECRET_KEY=$(grep ADMIN_SECRET_KEY "$PROJECT_ROOT/backend/.env" | cut -d '=' -f2)
    BASE_URL="http://localhost:8080"
    
    pretty_info "Target URL: ${BASE_URL}"
    pretty_info "Admin Secret Key: Loaded from .env file."

elif [[ "$TARGET_ENV" == "aws" ]]; then
    pretty_info "Configuring for AWS environment..."
    TF_DIR="$PROJECT_ROOT/terraform/main"
    
    # Get outputs from Terraform
    pretty_info "Fetching outputs from Terraform state..."
    BASE_URL=$(terraform -chdir="$TF_DIR" output -raw api_base_url)
    
    # Get admin secret from AWS Secrets Manager
    PROJECT_NAME=$(terraform -chdir="$TF_DIR" output -json | jq -r '.project_name.value // "resellio"')
    SECRET_NAME="${PROJECT_NAME}-admin-secret-key"

    pretty_info "Fetching Admin Secret Key from AWS Secrets Manager (Secret: $SECRET_NAME)..."
    export ADMIN_SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query SecretString --output text)
    
    if [[ -z "$BASE_URL" || -z "$ADMIN_SECRET_KEY" ]]; then
        pretty_error "Failed to retrieve necessary values from AWS. Ensure Terraform has been applied."
        exit 1
    fi
    
    pretty_info "Target URL: ${BASE_URL}"
    pretty_info "Admin Secret Key: Fetched from AWS Secrets Manager."
fi

# Run Tests 
gen_separator
pretty_info "Executing api_test.py..."
gen_separator

# The test script will now use the BASE_URL and the exported ADMIN_SECRET_KEY
python api_test.py --url "$BASE_URL"

TEST_EXIT_CODE=$?

gen_separator '='
if [[ $TEST_EXIT_CODE -eq 0 ]]; then
    pretty_success "All API tests passed for the '$TARGET_ENV' environment!"
else
    pretty_error "Some API tests failed for the '$TARGET_ENV' environment."
fi
gen_separator '='

exit $TEST_EXIT_CODE

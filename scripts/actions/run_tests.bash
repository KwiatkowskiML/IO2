#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
source "$SCRIPT_DIR/../utils/print.bash"

# Script parameters
TARGET_ENV="${1:-}"
TEST_SELECTOR="${2:-}"

# Validation
if [[ -z "$TARGET_ENV" || ("$TARGET_ENV" != "local" && "$TARGET_ENV" != "aws") ]]; then
    pretty_error "Invalid target environment. Usage: $0 <local|aws>"
    pretty_info "Usage: $0 <local|aws> [pytest_test_selector]"
    pretty_info "Example for specific test: $0 local \"tests/test_authentication.py::test_user_login\""
    pretty_info "Example for tests with keyword: $0 local \"-k login\""
    exit 1
fi

gen_separator '='
pretty_info "Starting API tests for environment: ${bold}${TARGET_ENV}${nc}"
if [[ -n "$TEST_SELECTOR" ]]; then
    pretty_info "Targeting specific test(s)/selector: ${bold}${TEST_SELECTOR}${nc}"
fi
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

    # Ensure .env file exists in project root
    if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
        pretty_warn ".env file not found. Copying from template."
        cp "$PROJECT_ROOT/.env.template" "$PROJECT_ROOT/.env"
    fi

    # Load ADMIN_SECRET_KEY and set API_BASE_URL from .env file for the tests
    export ADMIN_SECRET_KEY=$(grep ADMIN_SECRET_KEY "$PROJECT_ROOT/.env" | cut -d '=' -f2)
    export API_BASE_URL="http://localhost:8080" # Root of the gateway

    pretty_info "Target URL: ${API_BASE_URL}"
    pretty_info "Admin Secret Key: Loaded from .env file."

elif [[ "$TARGET_ENV" == "aws" ]]; then
    pretty_info "Configuring for AWS environment..."
    TF_DIR="$PROJECT_ROOT/terraform/main"

    # Get outputs from Terraform
    pretty_info "Fetching outputs from Terraform state..."
    BASE_URL=$(terraform -chdir="$TF_DIR" output -raw api_base_url)
    export API_BASE_URL="$BASE_URL" # Export for helper.py

    # Get admin secret from AWS Secrets Manager
    PROJECT_NAME=$(terraform -chdir="$TF_DIR" output -json | jq -r '.project_name.value // "resellio"')
    SECRET_NAME="${PROJECT_NAME}-admin-secret-key"

    pretty_info "Fetching Admin Secret Key from AWS Secrets Manager (Secret: $SECRET_NAME)..."
    export ADMIN_SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query SecretString --output text)

    if [[ -z "$API_BASE_URL" || -z "$ADMIN_SECRET_KEY" ]]; then
        pretty_error "Failed to retrieve necessary values from AWS. Ensure Terraform has been applied."
        exit 1
    fi

    pretty_info "Target URL: ${API_BASE_URL}"
    pretty_info "Admin Secret Key: Fetched from AWS Secrets Manager."
fi

# Run Tests
gen_separator
pretty_info "Executing pytest tests..."
gen_separator

PYTEST_CMD="pytest -v"
if [[ -n "$TEST_SELECTOR" ]]; then
    PYTEST_CMD="$PYTEST_CMD \"$TEST_SELECTOR\"" # Add selector if provided, ensure it's quoted
fi

# Execute the command
# Using eval to correctly interpret the quoted selector if it contains spaces or special pytest syntax (like -k "some name")
eval $PYTEST_CMD

TEST_EXIT_CODE=$?

gen_separator '='
if [[ $TEST_EXIT_CODE -eq 0 ]]; then
    pretty_success "All API tests passed for the '$TARGET_ENV' environment!"
else
    pretty_error "Some API tests failed for the '$TARGET_ENV' environment."
fi
gen_separator '='

exit $TEST_EXIT_CODE

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
source "$SCRIPT_DIR/../utils/print.bash"

# Script parameters
TARGET_ENV="${1:-local}"
ADMIN_EMAIL="${2:-admin@test.com}"
ADMIN_PASSWORD="${3:-AdminPassword123!}"

# Validation
if [[ "$TARGET_ENV" != "local" && "$TARGET_ENV" != "aws" ]]; then
    pretty_error "Invalid target environment. Usage: $0 <local|aws> [email] [password]"
    pretty_info "Usage: $0 <local|aws> [email] [password]"
    pretty_info "Example: $0 local admin@mycompany.com MySecurePassword123!"
    pretty_info "Default: $0 local admin@test.com AdminPassword123!"
    exit 1
fi

gen_separator '='
pretty_info "Creating admin account for environment: ${bold}${TARGET_ENV}${nc}"
pretty_info "Email: ${bold}${ADMIN_EMAIL}${nc}"
pretty_info "Password: ${bold}[HIDDEN]${nc}"
gen_separator '='

# Configure for Target Environment
if [[ "$TARGET_ENV" == "local" ]]; then
    pretty_info "Configuring for local Docker Compose environment..."

    # Ensure .env file exists in project root
    if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
        pretty_warn ".env file not found. Copying from template."
        cp "$PROJECT_ROOT/.env.template" "$PROJECT_ROOT/.env"
    fi

    # Load ADMIN_SECRET_KEY from .env file
    ADMIN_SECRET_KEY=$(grep ADMIN_SECRET_KEY "$PROJECT_ROOT/.env" | cut -d '=' -f2)
    API_BASE_URL="http://localhost:8080"

    pretty_info "Target URL: ${API_BASE_URL}"
    pretty_info "Admin Secret Key: Loaded from .env file"

elif [[ "$TARGET_ENV" == "aws" ]]; then
    pretty_info "Configuring for AWS environment..."
    TF_DIR="$PROJECT_ROOT/terraform/main"

    # Get outputs from Terraform
    pretty_info "Fetching outputs from Terraform state..."
    API_BASE_URL=$(terraform -chdir="$TF_DIR" output -raw api_base_url)

    # Get admin secret from AWS Secrets Manager
    PROJECT_NAME=$(terraform -chdir="$TF_DIR" output -json | jq -r '.project_name.value // "resellio"')
    SECRET_NAME="${PROJECT_NAME}-admin-secret-key"

    pretty_info "Fetching Admin Secret Key from AWS Secrets Manager (Secret: $SECRET_NAME)..."
    ADMIN_SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query SecretString --output text)

    if [[ -z "$API_BASE_URL" || -z "$ADMIN_SECRET_KEY" ]]; then
        pretty_error "Failed to retrieve necessary values from AWS. Ensure Terraform has been applied."
        exit 1
    fi

    pretty_info "Target URL: ${API_BASE_URL}"
    pretty_info "Admin Secret Key: Fetched from AWS Secrets Manager"
fi

# Prepare JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
    "email": "${ADMIN_EMAIL}",
    "login": "admin",
    "password": "${ADMIN_PASSWORD}",
    "first_name": "Admin",
    "last_name": "User",
    "admin_secret_key": "${ADMIN_SECRET_KEY}"
}
EOF
)

gen_separator
pretty_info "Creating admin account..."

# Check if API is reachable
if ! curl -sf "${API_BASE_URL}/health" > /dev/null 2>&1; then
    pretty_error "API Gateway is not reachable at ${API_BASE_URL}"
    pretty_info "Make sure the services are running:"
    pretty_info "For local: docker compose up -d"
    pretty_info "For AWS: Check if services are deployed"
    exit 1
fi

# Create admin account
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "${API_BASE_URL}/api/auth/register/admin" \
    -H "Content-Type: application/json" \
    -d "${JSON_PAYLOAD}")

# Extract HTTP status code and response body
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | head -n -1)

gen_separator

if [[ "$HTTP_CODE" == "201" ]]; then
    pretty_success "Admin account created successfully!"
    
    # Extract token from response if available
    if command -v jq >/dev/null 2>&1; then
        TOKEN=$(echo "$RESPONSE_BODY" | jq -r '.token // empty')
        MESSAGE=$(echo "$RESPONSE_BODY" | jq -r '.message // empty')
        
        if [[ -n "$MESSAGE" ]]; then
            pretty_info "Response: $MESSAGE"
        fi
        
        if [[ -n "$TOKEN" ]]; then
            pretty_info "Admin token generated successfully"
        fi
    else
        pretty_info "Response: $RESPONSE_BODY"
    fi
    
    gen_separator
    pretty_success "✅ Admin Login Credentials:"
    pretty_info "Email: ${bold}${ADMIN_EMAIL}${nc}"
    pretty_info "Password: ${bold}${ADMIN_PASSWORD}${nc}"
    gen_separator
    
elif [[ "$HTTP_CODE" == "400" ]]; then
    pretty_error "Failed to create admin account - Bad Request"
    
    if command -v jq >/dev/null 2>&1; then
        ERROR_DETAIL=$(echo "$RESPONSE_BODY" | jq -r '.detail // empty')
        if [[ -n "$ERROR_DETAIL" ]]; then
            pretty_error "Error: $ERROR_DETAIL"
            
            if [[ "$ERROR_DETAIL" == *"Email already registered"* ]]; then
                pretty_info "💡 The admin account already exists. You can login with:"
                pretty_info "Email: ${bold}${ADMIN_EMAIL}${nc}"
                pretty_info "Password: ${bold}${ADMIN_PASSWORD}${nc}"
                exit 0
            fi
        fi
    else
        pretty_error "Response: $RESPONSE_BODY"
    fi
    
elif [[ "$HTTP_CODE" == "403" ]]; then
    pretty_error "Failed to create admin account - Forbidden"
    pretty_error "Invalid admin secret key. Check your configuration."
    
elif [[ "$HTTP_CODE" == "422" ]]; then
    pretty_error "Failed to create admin account - Validation Error"
    
    if command -v jq >/dev/null 2>&1; then
        echo "$RESPONSE_BODY" | jq -r '.detail[]? | "- \(.msg) (field: \(.loc[-1]))"' | while read -r line; do
            pretty_error "$line"
        done
    else
        pretty_error "Response: $RESPONSE_BODY"
    fi
    
    pretty_info "💡 Password requirements:"
    pretty_info "- At least 8 characters"
    pretty_info "- Must contain uppercase and lowercase letters"
    pretty_info "- Must contain numbers"
    pretty_info "- Must contain special characters"
    
else
    pretty_error "Failed to create admin account - HTTP $HTTP_CODE"
    pretty_error "Response: $RESPONSE_BODY"
fi

gen_separator '='
if [[ "$HTTP_CODE" == "201" || ("$HTTP_CODE" == "400" && "$RESPONSE_BODY" == *"Email already registered"*) ]]; then
    pretty_success "Admin account is ready to use!"
    pretty_info "You can now login to the admin dashboard with the credentials above."
else
    pretty_error "Admin account creation failed."
fi
gen_separator '='

exit $([[ "$HTTP_CODE" == "201" || ("$HTTP_CODE" == "400" && "$RESPONSE_BODY" == *"Email already registered"*) ]] && echo 0 || echo 1) 
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
source "$SCRIPT_DIR/../utils/print.bash"

# Script parameters
SUITE="${1:-}"
TARGET_ENV="${2:-}"
TEST_SELECTOR="${3:-}"

# Function for Backend Tests 
run_backend_tests() {
    # Validation
    if [[ -z "$TARGET_ENV" || ("$TARGET_ENV" != "local" && "$TARGET_ENV" != "aws") ]]; then
        pretty_error "Invalid target environment for backend tests. Usage: $0 backend <local|aws> [pytest_selector]"
        exit 1
    fi

    # For local tests, this script will manage the Docker lifecycle.
    if [[ "$TARGET_ENV" == "local" ]]; then
        gen_separator '='
        pretty_info "Starting LOCAL Backend API test run (Docker-managed)"
        gen_separator '='

        cd "$PROJECT_ROOT"

        # Ensure .env file exists for Docker Compose to use
        if [[ ! -f ".env" ]]; then
            pretty_warn ".env file not found. Copying from template."
            cp ".env.template" ".env"
        fi

        # Start services in the background
        pretty_info "Building and starting services in the background..."
        docker compose up -d --build
        pretty_success "Services are starting."

        # Wait for API Gateway to be ready
        pretty_info "Waiting for API Gateway to become healthy..."
        timeout 120s bash -c '
          until curl -fs http://localhost:8080/health &>/dev/null; do
            echo "Waiting for API Gateway...";
            sleep 5;
          done
        '
        pretty_success "API Gateway is ready!"
    fi
    
    gen_separator '='
    pretty_info "Starting Backend API tests for environment: ${bold}${TARGET_ENV}${nc}"
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
        export ADMIN_SECRET_KEY=$(grep ADMIN_SECRET_KEY "$PROJECT_ROOT/.env" | cut -d '=' -f2)
        export API_BASE_URL="http://localhost:8080"
        pretty_info "Target URL: ${API_BASE_URL}"

    elif [[ "$TARGET_ENV" == "aws" ]]; then
        pretty_info "Configuring for AWS environment..."
        # ... (AWS logic remains unchanged)
        TF_DIR="$PROJECT_ROOT/terraform/main"
        pretty_info "Fetching outputs from Terraform state..."
        BASE_URL=$(terraform -chdir="$TF_DIR" output -raw api_base_url)
        export API_BASE_URL="$BASE_URL"
        PROJECT_NAME=$(terraform -chdir="$TF_DIR" output -json | jq -r '.project_name.value // "resellio"')
        SECRET_NAME="${PROJECT_NAME}-admin-secret-key"
        pretty_info "Fetching Admin Secret Key from AWS Secrets Manager (Secret: $SECRET_NAME)..."
        export ADMIN_SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query SecretString --output text)
        if [[ -z "$API_BASE_URL" || -z "$ADMIN_SECRET_KEY" ]]; then
            pretty_error "Failed to retrieve necessary values from AWS. Ensure Terraform has been applied."
            exit 1
        fi
        pretty_info "Target URL: ${API_BASE_URL}"
    fi

    # Run Tests
    gen_separator
    pretty_info "Executing pytest tests..."
    gen_separator

    PYTEST_CMD="pytest -v"
    if [[ -n "$TEST_SELECTOR" ]]; then
        PYTEST_CMD="$PYTEST_CMD \"$TEST_SELECTOR\""
    fi

    eval $PYTEST_CMD
    TEST_EXIT_CODE=$?

    # Cleanup Docker if we started it
    if [[ "$TARGET_ENV" == "local" ]]; then
        pretty_info "Cleaning up Docker services..."
        cd "$PROJECT_ROOT"
#        docker compose down -v
    fi

    gen_separator '='
    if [[ $TEST_EXIT_CODE -eq 0 ]]; then
        pretty_success "All API tests passed for the '$TARGET_ENV' environment!"
    else
        pretty_error "Some API tests failed for the '$TARGET_ENV' environment."
    fi
    gen_separator '='

    exit $TEST_EXIT_CODE
}

# Function for Frontend Tests 
run_frontend_tests() {
    # Validation
    if [[ -n "$TARGET_ENV" && "$TARGET_ENV" != "local" ]]; then
        pretty_warn "Frontend tests only run in 'local' environment. Ignoring '$TARGET_ENV'."
    fi

    gen_separator '='
    pretty_info "Starting Frontend (Flutter) tests for local Docker environment"
    gen_separator '='

    cd "$PROJECT_ROOT"

    # Ensure .env file exists for Docker Compose to use
    if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
        pretty_warn ".env file not found. Copying from template."
        cp "$PROJECT_ROOT/.env.template" "$PROJECT_ROOT/.env"
    fi

    # 1. Build and start all backend services in the background.
    pretty_info "Building and starting dependent services in the background..."
    docker compose up -d --build
    pretty_success "Backend services are starting."

    # 2. Wait for the API Gateway to be ready before running tests.
    pretty_info "Waiting for API Gateway to become healthy..."
    timeout 120s bash -c '
      until curl -fs http://localhost:8080/health &>/dev/null; do
        echo "Waiting for API Gateway...";
        sleep 5;
      done
    '
    pretty_success "API Gateway is ready!"

    # 3. Run the Flutter test container as a one-off task.
    pretty_info "Running Flutter test container..."
    docker compose run --rm flutter-tester
    TEST_EXIT_CODE=$?

    # 4. Clean up all services started by this script.
    pretty_info "Cleaning up all services..."
#    docker compose down -v

    gen_separator '='
    if [[ $TEST_EXIT_CODE -eq 0 ]]; then
        pretty_success "All Flutter tests passed!"
    else
        pretty_error "Some Flutter tests failed."
    fi
    gen_separator '='

    exit $TEST_EXIT_CODE
}


# Main Dispatcher 
case "$SUITE" in
    "backend")
        run_backend_tests
        ;;
    "frontend")
        run_frontend_tests
        ;;
    *)
        pretty_error "Invalid test suite. Usage: $0 <backend|frontend> [args...]"
        pretty_info "Backend tests: $0 backend <local|aws> [pytest_selector]"
        pretty_info "Frontend tests: $0 frontend [local]"
        exit 1
        ;;
esac

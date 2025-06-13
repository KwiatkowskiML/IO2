#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/../utils/print.bash"
ROOT_DIR=$(cd -- "$SCRIPT_DIR/../.." &>/dev/null && pwd)
cd "$ROOT_DIR" || exit 1

PROJECT_NAME="resellio"
AWS_REGION="eu-west-3" 

build_and_push_service() {
    local service_path="$1"
    local repo_name="$2"
    
    gen_separator
    pretty_info "Processing service at: $service_path"
    pretty_info "Target ECR Repository: $repo_name"
    gen_separator

    "$SCRIPT_DIR/push_docker_to_registry.bash" \
      "$service_path" \
      "$repo_name" \
      "$AWS_REGION"
}

pretty_info "Starting build & push process for all services..."

build_and_push_service "./backend/user_auth_service" "${PROJECT_NAME}-auth"
build_and_push_service "./backend/event_ticketing_service" "${PROJECT_NAME}-tickets"
build_and_push_service "./backend/db_init" "${PROJECT_NAME}-db-init"

gen_separator '='
pretty_success "All services have been successfully built and pushed to ECR."
gen_separator '='

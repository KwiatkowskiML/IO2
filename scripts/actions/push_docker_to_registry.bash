#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/../utils/print.bash"

# Script parameters
DOCKER_FOLDER_PATH_ARG="${1:-}" # Docker folder path from the first argument
CUSTOM_REPO_NAME_ARG="${2:-}"   # Optional custom repository name from the second argument
AWS_REGION="${3:-eu-west-3}"    # Optional AWS region from the third argument

# Validate Docker folder path
if [[ -z "$DOCKER_FOLDER_PATH_ARG" ]]; then
    pretty_error "Docker folder path is required as the first argument."
    pretty_info "Usage: $0 <path_to_docker_folder> [custom_repository_name]"
    exit 1
fi

# Convert to absolute path to ensure it works regardless of call location
DOCKER_FOLDER_PATH=$(realpath "$DOCKER_FOLDER_PATH_ARG")

if [[ ! -d "$DOCKER_FOLDER_PATH" ]]; then
    pretty_error "Docker folder path '$DOCKER_FOLDER_PATH' does not exist or is not a directory."
    exit 1
fi

if [[ ! -f "$DOCKER_FOLDER_PATH/Dockerfile" ]]; then
    pretty_error "No Dockerfile found in '$DOCKER_FOLDER_PATH'."
    exit 1
fi

# Determine Repository Name
if [[ -n "$CUSTOM_REPO_NAME_ARG" ]]; then
    REPO_NAME="$CUSTOM_REPO_NAME_ARG"
    pretty_info "Using custom repository name: $REPO_NAME"
else
    REPO_NAME=$(basename "$DOCKER_FOLDER_PATH") # Use folder name as default repository name
    pretty_info "Using folder name as repository name: $REPO_NAME"
fi

# AWS Setup
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [[ -z "$ACCOUNT_ID" ]]; then
    pretty_error "Could not retrieve AWS Account ID. Make sure AWS CLI is configured correctly."
    exit 1
fi
pretty_info "Using AWS Account ID: $ACCOUNT_ID"
pretty_info "Using AWS Region: $AWS_REGION"

# ECR Repository Management
pretty_info "Ensuring ECR repository '$REPO_NAME' exists in region '$AWS_REGION'"
if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    pretty_success "ECR repository '$REPO_NAME' already exists."
else
    pretty_info "ECR repository '$REPO_NAME' does not exist. Creating it..."
    if aws ecr create-repository --repository-name "$REPO_NAME" --image-scanning-configuration scanOnPush=true --region "$AWS_REGION"; then
        pretty_success "ECR repository '$REPO_NAME' created successfully."
    else
        pretty_error "Failed to create ECR repository '$REPO_NAME'."
        exit 1
    fi
fi

# Docker ECR Authentication
pretty_info "Authenticating Docker to ECR for '$AWS_REGION'"
if aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"; then
    pretty_success "Docker ECR authentication successful."
else
    pretty_error "Docker ECR authentication failed."
    exit 1
fi

# Docker Build
pretty_info "Building Docker image '$REPO_NAME:latest' from path '$DOCKER_FOLDER_PATH'"
if docker build -t "$REPO_NAME:latest" "$DOCKER_FOLDER_PATH"; then
    pretty_success "Docker image '$REPO_NAME:latest' built successfully."
else
    pretty_error "Docker image build failed."
    exit 1
fi

# Docker Tag & Push
ECR_IMAGE_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest"
pretty_info "Tagging image '$REPO_NAME:latest' as '$ECR_IMAGE_URI'"
if docker tag "$REPO_NAME:latest" "$ECR_IMAGE_URI"; then
    pretty_success "Image tagged successfully."
else
    pretty_error "Image tagging failed."
    exit 1
fi

pretty_info "Pushing image '$ECR_IMAGE_URI' to ECR"
if docker push "$ECR_IMAGE_URI"; then
    pretty_success "✓ Image '$ECR_IMAGE_URI' pushed successfully to ECR!"
else
    pretty_error "Image push to ECR failed."
    exit 1
fi

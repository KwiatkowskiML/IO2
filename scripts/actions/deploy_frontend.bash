#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
source "$SCRIPT_DIR/../utils/print.bash"

TF_DIR="$PROJECT_ROOT/terraform/main"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

gen_separator '='
pretty_info "Starting Frontend Deployment to AWS"
gen_separator '='

# 1. Fetch required values from Terraform state
pretty_info "Fetching deployment configuration from Terraform..."
FRONTEND_URL=$(terraform -chdir="$TF_DIR" output -raw frontend_url)
S3_BUCKET=$(terraform -chdir="$TF_DIR" output -raw frontend_s3_bucket_name)
CLOUDFRONT_ID=$(terraform -chdir="$TF_DIR" output -raw frontend_cloudfront_distribution_id)

if [[ -z "$FRONTEND_URL" || -z "$S3_BUCKET" || -z "$CLOUDFRONT_ID" ]]; then
    pretty_error "Failed to retrieve necessary deployment values from Terraform."
    pretty_error "Ensure Terraform has been applied successfully in '$TF_DIR'."
    exit 1
fi

API_BASE_URL="${FRONTEND_URL}/api"

pretty_success "Configuration loaded:"
pretty_clean "  > API URL for build: $API_BASE_URL"
pretty_clean "  > S3 Bucket:         $S3_BUCKET"
pretty_clean "  > CloudFront ID:     $CLOUDFRONT_ID"

# 2. Build the Flutter web application
gen_separator
pretty_info "Building Flutter web application with API base: $API_BASE_URL"
gen_separator

cd "$FRONTEND_DIR"

if ! flutter build web --dart-define=API_BASE_URL="$API_BASE_URL"; then
    pretty_error "Flutter build failed."
    exit 1
fi
pretty_success "Flutter web application built successfully."

# 3. Synchronize build output with S3
gen_separator
pretty_info "Uploading built files to S3 bucket: $S3_BUCKET"
gen_separator

BUILD_DIR="$FRONTEND_DIR/build/web"

if ! aws s3 sync "$BUILD_DIR" "s3://$S3_BUCKET" --delete --acl private; then
    pretty_error "S3 sync failed."
    exit 1
fi
pretty_success "Files successfully uploaded to S3."

# 4. Invalidate the CloudFront cache
gen_separator
pretty_info "Invalidating CloudFront cache to deploy changes..."
gen_separator

if ! aws cloudfront create-invalidation --distribution-id "$CLOUDFRONT_ID" --paths "/*"; then
    pretty_error "CloudFront invalidation failed."
    pretty_warn "Changes may take some time to appear."
    exit 1
fi
pretty_success "CloudFront invalidation created successfully."

gen_separator '='
pretty_success "Frontend deployment complete!"
pretty_info "Your application is available at: $FRONTEND_URL"
gen_separator '='

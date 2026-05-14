#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# APK Security Audit Pipeline — Deployment Script
# ═══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
DOCKER_DIR="${PROJECT_ROOT}/docker"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }
info() { echo -e "${CYAN}[i]${NC} $*"; }

# ─── Configuration (override via env vars) ───────────────────
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-prod}"
JADX_IMAGE_TAG="${JADX_IMAGE_TAG:-latest}"
MOBSF_IMAGE_TAG="${MOBSF_IMAGE_TAG:-latest}"
OTEL_IMAGE_TAG="${OTEL_IMAGE_TAG:-0.114.0}"
ALARM_EMAIL="${ALARM_EMAIL:-}"

# ─── 1. Prerequisite Checks ──────────────────────────────────
check_prereqs() {
    info "Checking prerequisites..."

    # Terraform
    if ! command -v terraform &> /dev/null; then
        err "terraform not found. Install via: winget install HashiCorp.Terraform"
        exit 1
    fi
    TF_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
    log "terraform ${TF_VERSION}"

    # AWS CLI
    if ! command -v aws &> /dev/null; then
        err "aws CLI not found. Install via: msiexec /i AWSCLIV2.msi /quiet"
        exit 1
    fi
    AWS_CLI_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    log "aws CLI ${AWS_CLI_VERSION}"

    # Docker
    if ! command -v docker &> /dev/null; then
        err "docker not found. Install Docker Desktop for Windows."
        exit 1
    fi
    DOCKER_VERSION=$(docker --version 2>&1 | cut -d' ' -f3 | tr -d ',')
    log "docker ${DOCKER_VERSION}"

    # AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        err "AWS credentials not configured. Run: aws configure"
        exit 1
    fi
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    log "AWS account: ${ACCOUNT_ID}"
    log "AWS region: ${AWS_REGION}"

    # jadx (for local Docker build context)
    JADX_PATH="${JADX_PATH:-E:/Compressed/jadx-1.5.5}"
    if [ ! -d "${JADX_PATH}" ]; then
        warn "jadx not found at ${JADX_PATH} — Docker build uses remote download"
    else
        log "jadx found at ${JADX_PATH}"
    fi
}

# ─── 2. Terraform Init, Plan, Apply ──────────────────────────
run_terraform() {
    info "Running Terraform..."
    cd "${TERRAFORM_DIR}"

    terraform fmt -check -recursive || warn "Some files need formatting"

    log "terraform init..."
    terraform init -upgrade

    log "terraform validate..."
    terraform validate

    log "terraform plan..."
    terraform plan \
        -var="environment=${ENVIRONMENT}" \
        -var="aws_region=${AWS_REGION}" \
        -var="app_image_tag=${JADX_IMAGE_TAG}" \
        -var="otel_image_tag=${OTEL_IMAGE_TAG}" \
        ${ALARM_EMAIL:+ -var="alarm_email=${ALARM_EMAIL}"} \
        -out=tfplan

    log "terraform apply..."
    terraform apply -auto-approve tfplan

    # Capture outputs
    ECR_JADX_URL=$(terraform output -raw jadx_repo_url)
    ECR_MOBSF_URL=$(terraform output -raw mobsf_repo_url)
    ECR_OTEL_URL="${ECR_JADX_URL%/*}/$(terraform output -raw jadx_repo_url | cut -d'/' -f1)-otel-collector"
    S3_UPLOAD_BUCKET=$(terraform output -raw apk_uploads_bucket_name)
    S3_REPORT_BUCKET=$(terraform output -raw audit_reports_bucket_name)
    STATE_MACHINE_ARN=$(terraform output -raw state_machine_arn)
    DYNAMO_TABLE=$(terraform output -raw findings_table_name)

    log "Terraform outputs captured"
    info "  ECR jadx:      ${ECR_JADX_URL}"
    info "  ECR MobSF:     ${ECR_MOBSF_URL}"
    info "  S3 uploads:    ${S3_UPLOAD_BUCKET}"
    info "  S3 reports:    ${S3_REPORT_BUCKET}"
    info "  State Machine: ${STATE_MACHINE_ARN}"
    info "  DynamoDB:      ${DYNAMO_TABLE}"

    # Export for later steps
    export ECR_JADX_URL ECR_MOBSF_URL ECR_OTEL_URL
    export S3_UPLOAD_BUCKET S3_REPORT_BUCKET STATE_MACHINE_ARN DYNAMO_TABLE
}

# ─── 3. Build and Push Docker Images ─────────────────────────
build_and_push() {
    info "Building and pushing Docker images..."

    # Authenticate to ECR
    aws ecr get-login-password --region "${AWS_REGION}" | \
        docker login --username AWS --password-stdin "${ECR_JADX_URL%%/*}"

    # Build jadx
    log "Building jadx image..."
    docker build \
        -t "${ECR_JADX_URL}:${JADX_IMAGE_TAG}" \
        -t "${ECR_JADX_URL}:latest" \
        "${DOCKER_DIR}/jadx/"

    log "Pushing jadx to ECR..."
    docker push "${ECR_JADX_URL}:${JADX_IMAGE_TAG}"
    docker push "${ECR_JADX_URL}:latest"

    # Build MobSF
    log "Building MobSF image..."
    docker build \
        -t "${ECR_MOBSF_URL}:${MOBSF_IMAGE_TAG}" \
        -t "${ECR_MOBSF_URL}:latest" \
        "${DOCKER_DIR}/mobsf/"

    log "Pushing MobSF to ECR..."
    docker push "${ECR_MOBSF_URL}:${MOBSF_IMAGE_TAG}"
    docker push "${ECR_MOBSF_URL}:latest"

    # Pull and push OTel collector
    log "Pulling OTel collector image..."
    docker pull "otel/opentelemetry-collector-contrib:${OTEL_IMAGE_TAG}"

    OTel_ECR_URL="$(echo "${ECR_JADX_URL}" | sed 's/-jadx/-otel-collector/')"
    docker tag "otel/opentelemetry-collector-contrib:${OTEL_IMAGE_TAG}" "${OTel_ECR_URL}:${OTEL_IMAGE_TAG}"
    docker tag "otel/opentelemetry-collector-contrib:${OTEL_IMAGE_TAG}" "${OTel_ECR_URL}:latest"

    log "Pushing OTel collector to ECR..."
    docker push "${OTel_ECR_URL}:${OTEL_IMAGE_TAG}"
    docker push "${OTel_ECR_URL}:latest"

    log "All images pushed successfully"
    export OTEL_ECR_URL
}

# ─── 4. Verify OTLP Collector Health ─────────────────────────
verify_otel_health() {
    info "Verifying OTel collector health..."

    # Run OTel collector container briefly and check health endpoint
    HEALTH_CONTAINER="otel-health-check-$$"
    docker run -d --name "${HEALTH_CONTAINER}" \
        -p 13133:13133 \
        "otel/opentelemetry-collector-contrib:${OTEL_IMAGE_TAG}" \
        > /dev/null 2>&1

    # Wait for startup
    sleep 5

    if curl -s -o /dev/null -w "%{http_code}" http://localhost:13133/health | grep -q "200"; then
        log "OTel collector health endpoint OK (HTTP 200)"
    else
        warn "OTel collector health endpoint not responding — check ECS task logs after deployment"
    fi

    docker stop "${HEALTH_CONTAINER}" > /dev/null 2>&1
    docker rm "${HEALTH_CONTAINER}" > /dev/null 2>&1
}

# ─── 5. Post-Deployment Verification ─────────────────────────
verify_deployment() {
    info "Running post-deployment verification..."

    # Check S3 bucket encryption
    ENC=$(aws s3api get-bucket-encryption --bucket "${S3_UPLOAD_BUCKET}" \
        --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' \
        --output text 2>/dev/null || echo "NONE")
    if [ "${ENC}" = "aws:kms" ]; then
        log "S3 encryption: aws:kms (AES-256 with KMS CMK)"
    else
        warn "S3 encryption not aws:kms: got ${ENC}"
    fi

    # Check Step Functions state machine
    SM_STATUS=$(aws stepfunctions describe-state-machine \
        --state-machine-arn "${STATE_MACHINE_ARN}" \
        --query 'status' --output text 2>/dev/null || echo "MISSING")
    if [ "${SM_STATUS}" = "ACTIVE" ]; then
        log "Step Functions state machine: ACTIVE"
    else
        warn "Step Functions state machine status: ${SM_STATUS}"
    fi

    # Check DynamoDB table
    TABLE_STATUS=$(aws dynamodb describe-table \
        --table-name "${DYNAMO_TABLE}" \
        --query 'Table.TableStatus' --output text 2>/dev/null || echo "MISSING")
    if [ "${TABLE_STATUS}" = "ACTIVE" ]; then
        log "DynamoDB table: ACTIVE"
    else
        warn "DynamoDB table status: ${TABLE_STATUS}"
    fi

    # Check ECR repositories
    for repo in "apk-audit-prod-jadx" "apk-audit-prod-mobsf"; do
        if aws ecr describe-repositories --repository-names "${repo}" &> /dev/null; then
            log "ECR repo ${repo}: exists"
        else
            warn "ECR repo ${repo}: not found"
        fi
    done

    # Check VPC endpoints
    VPCE_COUNT=$(aws ec2 describe-vpc-endpoints \
        --filters "Name=tag:ManagedBy,Values=terraform" \
        --query 'length(VpcEndpoints)' --output text)
    info "VPC endpoints found: ${VPCE_COUNT}"

    # Smoke test: upload a small test file and verify S3 notification
    log "Smoke test: uploading test APK marker..."
    echo "test" > /tmp/test.apk
    aws s3 cp /tmp/test.apk "s3://${S3_UPLOAD_BUCKET}/test-$(date +%s).apk"
    log "Test APK uploaded — check Step Functions console for execution"

    log "Deployment verification complete"
}

# ─── Main ────────────────────────────────────────────────────
main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║   APK Security Audit Pipeline — AWS Deployment         ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""

    check_prereqs
    echo ""
    run_terraform
    echo ""
    build_and_push
    echo ""
    verify_otel_health
    echo ""
    verify_deployment
    echo ""

    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  Deployment Complete!                                   ║"
    echo "║                                                        ║"
    echo "║  Upload APKs to:                                       ║"
    echo "║    s3://${S3_UPLOAD_BUCKET}/                        ║"
    echo "║                                                        ║"
    echo "║  Monitor executions:                                   ║"
    echo "║    aws stepfunctions list-executions \\                ║"
    echo "║      --state-machine-arn ${STATE_MACHINE_ARN}          ║"
    echo "║                                                        ║"
    echo "║  View findings:                                        ║"
    echo "║    aws dynamodb scan --table-name ${DYNAMO_TABLE}      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
}

main "$@"

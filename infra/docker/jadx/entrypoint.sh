#!/bin/bash
set -euo pipefail

echo "[jadx] Starting decompilation — Job: ${JOB_ID}"

: "${S3_BUCKET:?S3_BUCKET not set}"
: "${S3_KEY:?S3_KEY not set}"
: "${REPORTS_BUCKET:?REPORTS_BUCKET not set}"
: "${JOB_ID:?JOB_ID not set}"

INPUT_APK="/tmp/input.apk"
OUTPUT_DIR="/tmp/decompiled"

# Download APK from S3
echo "[jadx] Downloading s3://${S3_BUCKET}/${S3_KEY}"
aws s3 cp "s3://${S3_BUCKET}/${S3_KEY}" "${INPUT_APK}" --no-progress

# Verify APK integrity
if ! unzip -t "${INPUT_APK}" > /dev/null 2>&1; then
    echo "[jadx] ERROR: Invalid or corrupted APK file"
    # Write error state for downstream handling
    echo "{\"status\":\"error\",\"message\":\"Invalid APK file\"}" > /tmp/status.json
    aws s3 cp /tmp/status.json "s3://${REPORTS_BUCKET}/decompiled/${JOB_ID}/status.json" --no-progress
    exit 1
fi

# Decompile
echo "[jadx] Decompiling APK..."
mkdir -p "${OUTPUT_DIR}"
jadx --deobf --show-bad-code --comments-level none \
     -d "${OUTPUT_DIR}" \
     "${INPUT_APK}" 2>&1 | tail -20

if [ ! -d "${OUTPUT_DIR}/sources" ]; then
    echo "[jadx] ERROR: Decompilation produced no sources"
    echo "{\"status\":\"error\",\"message\":\"No sources produced by jadx\"}" > /tmp/status.json
    aws s3 cp /tmp/status.json "s3://${REPORTS_BUCKET}/decompiled/${JOB_ID}/status.json" --no-progress
    exit 1
fi

# Upload decompiled sources to S3
echo "[jadx] Uploading decompiled sources to s3://${REPORTS_BUCKET}/decompiled/${JOB_ID}/"
aws s3 cp "${OUTPUT_DIR}" "s3://${REPORTS_BUCKET}/decompiled/${JOB_ID}/" \
    --recursive --no-progress

# Write success status
echo "{\"status\":\"success\",\"decompiled_files\":$(find "${OUTPUT_DIR}" -type f | wc -l)}" > /tmp/status.json
aws s3 cp /tmp/status.json "s3://${REPORTS_BUCKET}/decompiled/${JOB_ID}/status.json" --no-progress

echo "[jadx] Decompilation complete"

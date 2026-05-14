#!/bin/bash
set -euo pipefail

echo "[mobsf] Starting scan — Job: ${JOB_ID}"

: "${REPORTS_BUCKET:?REPORTS_BUCKET not set}"
: "${JOB_ID:?JOB_ID not set}"

SOURCE_DIR="/tmp/source"
OUTPUT_FILE="/tmp/mobsf_output.json"

# Download decompiled sources from S3
echo "[mobsf] Downloading decompiled sources from s3://${REPORTS_BUCKET}/decompiled/${JOB_ID}/"
mkdir -p "${SOURCE_DIR}"
aws s3 cp "s3://${REPORTS_BUCKET}/decompiled/${JOB_ID}/" "${SOURCE_DIR}/" \
    --recursive --no-progress

# Check if sources were downloaded
if [ -z "$(ls -A ${SOURCE_DIR}/sources 2>/dev/null)" ]; then
    echo "[mobsf] WARNING: No sources found in decompiled output"
    echo '{"status":"warning","message":"No sources found","results":[]}' > "${OUTPUT_FILE}"
else
    # Run MobSF scan
    echo "[mobsf] Running MobSF static analysis..."
    mobsfscan "${SOURCE_DIR}" --json -o "${OUTPUT_FILE}" 2>&1 | tail -20

    if [ ! -s "${OUTPUT_FILE}" ]; then
        echo "[mobsf] WARNING: MobSF produced empty output, creating fallback"
        echo '{"status":"warning","message":"MobSF produced empty output","results":[]}' > "${OUTPUT_FILE}"
    fi
fi

# Upload results to S3
echo "[mobsf] Uploading results to s3://${REPORTS_BUCKET}/mobsf-output/${JOB_ID}.json"
aws s3 cp "${OUTPUT_FILE}" "s3://${REPORTS_BUCKET}/mobsf-output/${JOB_ID}.json" \
    --no-progress

echo "[mobsf] Scan complete"

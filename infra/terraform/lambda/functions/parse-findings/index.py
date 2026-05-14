"""APK Audit Pipeline — Parse MobSF findings and store to DynamoDB."""
import json
import os
import uuid
import time
from datetime import datetime, timezone

import boto3
from botocore.config import Config

s3 = boto3.client("s3", config=Config(max_pool_connections=25))
dynamodb = boto3.client("dynamodb")

FINDINGS_TABLE = os.environ["FINDINGS_TABLE_NAME"]
REPORTS_BUCKET = os.environ["REPORTS_BUCKET"]

# Patterns indicating hardcoded secrets
SECRET_PATTERNS = [
    "api_key", "api_secret", "secret_key", "private_key",
    "password", "passwd", "token", "auth_token",
    "aws_access_key", "aws_secret", "client_secret",
    "db_password", "database_url", "connection_string",
    "firebase_key", "google_api_key", "stripe_key",
]


def compute_apk_hash(apk_key):
    """Derive a stable hash from the S3 key for DynamoDB partition key."""
    import hashlib
    return hashlib.sha256(apk_key.encode()).hexdigest()[:16]


def extract_findings(mobsf_data):
    """Parse MobSF JSON output and extract security-relevant findings."""
    findings = []
    timestamp_now = int(time.time())

    if isinstance(mobsf_data, list):
        entries = mobsf_data
    elif isinstance(mobsf_data, dict):
        entries = mobsf_data.get("results", mobsf_data.get("findings", []))
    else:
        entries = []

    for entry in entries:
        if not isinstance(entry, dict):
            continue

        severity = entry.get("severity", entry.get("level", "MEDIUM")).upper()
        if severity not in ("HIGH", "CRITICAL"):
            continue

        finding_type = entry.get("type", entry.get("rule_id", "unknown"))
        description = entry.get("description", entry.get("message", ""))
        file_path = entry.get("file", entry.get("file_path", ""))
        line_number = entry.get("line", entry.get("line_number", 0))

        # Classify finding
        desc_lower = description.lower() + file_path.lower()
        if any(p in desc_lower for p in SECRET_PATTERNS):
            finding_type = "hardcoded_secret"
        elif "exported" in desc_lower or "receiver" in desc_lower:
            finding_type = "exported_component"
        elif "network" in desc_lower and "security" in desc_lower:
            finding_type = "network_security_config"
        elif "permission" in desc_lower:
            finding_type = "permission_misconfig"
        elif "webview" in desc_lower:
            finding_type = "webview_issue"

        findings.append({
            "finding_id": str(uuid.uuid4()),
            "finding_type": finding_type,
            "severity": severity,
            "file_path": file_path,
            "line_number": int(line_number) if line_number else 0,
            "description": description[:1000],
            "timestamp": timestamp_now,
        })

    return findings


def batch_write_to_dynamodb(apk_hash, findings):
    """Write findings in batches of 25 to DynamoDB."""
    if not findings:
        return 0

    items = []
    for f in findings:
        items.append({
            "PutRequest": {
                "Item": {
                    "apk_hash": {"S": apk_hash},
                    "finding_id": {"S": f["finding_id"]},
                    "finding_type": {"S": f["finding_type"]},
                    "severity": {"S": f["severity"]},
                    "file_path": {"S": f["file_path"]},
                    "line_number": {"N": str(f["line_number"])},
                    "description": {"S": f["description"]},
                    "timestamp": {"N": str(f["timestamp"])},
                    "created_at": {"S": datetime.now(timezone.utc).isoformat()},
                }
            }
        })

    written = 0
    for i in range(0, len(items), 25):
        batch = items[i:i + 25]
        try:
            dynamodb.batch_write_item(RequestItems={FINDINGS_TABLE: batch})
            written += len(batch)
        except Exception as e:
            print(f"DynamoDB batch write error: {e}")
            # Retry individually
            for item in batch:
                try:
                    dynamodb.put_item(TableName=FINDINGS_TABLE, Item=item["PutRequest"]["Item"])
                    written += 1
                except Exception as e2:
                    print(f"DynamoDB put_item error: {e2}")

    return written


def handler(event, context):
    """Main handler: called by Step Functions to parse MobSF output.

    Expects: reportsBucket, jobId, apkBucket, apkKey, executionArn
    """
    reports_bucket = event.get("reportsBucket", REPORTS_BUCKET)
    job_id = event.get("jobId", context.aws_request_id)
    apk_key = event.get("apkKey", "unknown.apk")
    mobsf_key = f"mobsf-output/{job_id}.json"

    apk_hash = compute_apk_hash(apk_key)

    # Read MobSF JSON output
    try:
        response = s3.get_object(Bucket=reports_bucket, Key=mobsf_key)
        mobsf_data = json.loads(response["Body"].read().decode("utf-8"))
    except s3.exceptions.NoSuchKey:
        print(f"MobSF output not found: s3://{reports_bucket}/{mobsf_key}")
        return {
            "findingsCount": 0,
            "criticalCount": 0,
            "highCount": 0,
            "hasCritical": False,
            "reportS3Key": f"final-reports/{job_id}.json",
            "status": "no_mobsf_output",
        }

    findings = extract_findings(mobsf_data)
    critical_count = sum(1 for f in findings if f["severity"] == "CRITICAL")
    high_count = sum(1 for f in findings if f["severity"] == "HIGH")

    # Write to DynamoDB
    written = batch_write_to_dynamodb(apk_hash, findings)

    # Save intermediate parsed result
    parsed_key = f"final-reports/{job_id}.json"
    report = {
        "executionId": event.get("executionArn", context.aws_request_id),
        "apkKey": apk_key,
        "apkHash": apk_hash,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "totalFindings": len(findings),
        "criticalCount": critical_count,
        "highCount": high_count,
        "dynamoDbWritten": written,
        "findings": findings,
    }
    s3.put_object(
        Bucket=reports_bucket,
        Key=parsed_key,
        Body=json.dumps(report, indent=2),
        ContentType="application/json",
    )

    print(f"Parsed {len(findings)} findings ({critical_count} critical, {high_count} high). Wrote {written} to DynamoDB.")

    return {
        "findingsCount": len(findings),
        "criticalCount": critical_count,
        "highCount": high_count,
        "hasCritical": critical_count > 0,
        "hasHigh": high_count > 0,
        "dynamoDbWritten": written,
        "reportS3Key": parsed_key,
        "status": "success",
    }


def save_report_handler(event, context):
    """Save report handler: finalize the audit report in S3.

    Called as a separate Step Functions state after DynamoDB write + SNS notification.
    """
    reports_bucket = event.get("reportsBucket", REPORTS_BUCKET)
    job_id = event.get("jobId", context.aws_request_id)
    apk_key = event.get("apkKey", "unknown.apk")

    findings_payload = event.get("findings", {})
    if isinstance(findings_payload, dict) and "Payload" in findings_payload:
        findings_payload = findings_payload["Payload"]

    report = {
        "executionId": event.get("executionArn", context.aws_request_id),
        "apkKey": apk_key,
        "auditCompletedAt": datetime.now(timezone.utc).isoformat(),
        "summary": {
            "findingsCount": findings_payload.get("findingsCount", 0),
            "criticalCount": findings_payload.get("criticalCount", 0),
            "highCount": findings_payload.get("highCount", 0),
            "dynamoDbWritten": findings_payload.get("dynamoDbWritten", 0),
        },
        "status": findings_payload.get("status", "completed"),
    }

    report_key = f"final-reports/{job_id}.json"
    s3.put_object(
        Bucket=reports_bucket,
        Key=report_key,
        Body=json.dumps(report, indent=2),
        ContentType="application/json",
        ServerSideEncryption="aws:kms",
    )

    print(f"Final report saved: s3://{reports_bucket}/{report_key}")

    return {
        "reportS3Key": report_key,
        "findingsCount": report["summary"]["findingsCount"],
        "criticalCount": report["summary"]["criticalCount"],
    }

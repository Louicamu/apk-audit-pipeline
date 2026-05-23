# DroidSentinel — Serverless APK Security Pipeline

> **AWS Prompt the Planet Challenge 2026 Submission**
>
> A single AI prompt that generates a complete, production-ready, serverless Android APK security auditing pipeline on AWS. 45+ infrastructure files, 8 Terraform modules, zero placeholders.

---

## Pipeline Verification (Local Test — May 23, 2026)

The pipeline was verified end-to-end with a 92MB production APK (DoorDash v15.184.13):

| Stage | Tool | Result |
|-------|------|--------|
| Decompile | jadx 1.5.5 | 92 MB APK → **46,639 Java source files** |
| Scan | mobsfscan v0.4.5 | **6 security findings across all 46k files** |
| Secrets search | ripgrep (Lambda parity) | Google API Key, Firebase config, OpenTok/Vonage API Key, InCode SDK Token, Lokalise API Key |
| Output | JSON | Structured finding report with CWE, OWASP, MASVS mappings |

### Sample findings from scan:

| Finding | CWE | OWASP |
|---------|-----|-------|
| Certificate Pinning Not Enforced | CWE-295 | M3: Insecure Communication |
| Certificate Transparency Missing | CWE-295 | M3: Insecure Communication |
| Tapjacking Prevention Missing | CWE-200 | M1: Improper Platform Usage |
| Screenshot Prevention Missing | CWE-200 | M2: Insecure Data Storage |
| Root Detection Missing | CWE-919 | M8: Code Tampering |
| SafetyNet API Not Used | CWE-353 | M8: Code Tampering |

### Sensitive references detected (Lambda classification parity):

- `google_api_key` — runtime config reference (ye/C64573h.java)
- `openTokApiKey` — Vonage/OpenTok API key (com/incode/welcome_sdk)
- `X-Lokalise-Api-Key` — Lokalise SDK header (com/lokalise/sdk)
- `X-Incode-Api-Key` — InCode biometric SDK header
- Firebase project config (database_url, gcm_senderId, storage_bucket, trackingId)

---

## Architecture

```
S3 APK Upload ──> EventBridge ──> Step Functions State Machine
                                       │
     ┌─────────────────────────────────┤
     ▼                                 ▼
[Fargate SPOT: jadx]          [Fargate SPOT: MobSF]
 Decompile APK → source        Static analysis → JSON
     │                                 │
     └───────── S3 (KMS encrypted) ────┘
                    │
                    ▼
         [Lambda: Parse Findings]
          Classify + DynamoDB write
                    │
          ┌────────┴──────────┐
          ▼                   ▼
    [SNS Alert]       [Lambda: Save Report]
    if CRITICAL             Final JSON → S3
```

---

## The Prompt

Copy and paste this into Claude Code, Kiro, Cursor, or any AI coding assistant:

```
Role: Senior Cloud Security Architect

Task: Design and deploy a production-ready, serverless Android APK security
auditing pipeline on AWS using Infrastructure as Code.

1. INFRASTRUCTURE AS CODE (Terraform)
Generate modular Terraform with 8 modules:

- networking: VPC (10.0.0.0/16) across 2 AZs, public + private subnets,
  NAT Gateway per AZ, 7 VPC Endpoints (S3 gateway, DynamoDB gateway,
  ECR API, ECR DKR, CloudWatch Logs, X-Ray, STS — all interface endpoints
  with private DNS).

- s3: Two KMS-encrypted buckets (apk-uploads, audit-reports). CMK with
  90-day rotation. AES-256 (aws:kms) with bucket key. Versioning enabled.
  Intelligent-Tiering at 0 days. 90-day expiration. Block all public access.
  EventBridge notifications on uploads bucket.

- dynamodb: Findings table (apk_hash + finding_id key). PAY_PER_REQUEST.
  PITR enabled. GSI severity-index. KMS encrypted.

- ecr: Three repos (jadx, mobsf, otel-collector). IMMUTABLE tags.
  scan_on_push enabled. Keep last 5 images.

- iam: Six least-privilege roles. Each scoped to specific resources.
  No wildcard ARNs for data access.

- ecs: Fargate cluster with FARGATE_SPOT (65% savings). Two task
  definitions with OpenTelemetry sidecar containers.

- lambda: Two Python 3.11 ARM64 functions for findings parsing and
  report generation. VPC-attached, X-Ray active tracing.

- step-functions: Standard state machine with EventBridge S3 trigger,
  retry logic, error handling. 7 states.

- observability: X-Ray, CloudWatch dashboard, SNS topics, alarms.

2. DOCKER CONTAINERS
jadx: eclipse-temurin:17-jre + AWS CLI + jadx 1.5.3
mobsf: python:3.11-slim + AWS CLI + mobsfscan

3. OpenTelemetry SIDECAR
OTel collector with OTLP gRPC → X-Ray exporter

4. DEPLOYMENT SCRIPT
Single deploy.sh: prereq checks → terraform → docker build+push →
health verification → smoke test

Output complete, production-ready code. Every file fully implemented —
no TODOs.
```

---

## Module Breakdown

| # | Module | Resources |
|---|--------|-----------|
| 1 | **networking** | VPC, 4 subnets, 2 NAT GW, IGW, 7 VPC Endpoints, Security Group |
| 2 | **s3** | 2 KMS-encrypted buckets, lifecycle policies, EventBridge notifications |
| 3 | **dynamodb** | Findings table with GSI, PITR, KMS encryption |
| 4 | **ecr** | 3 immutable repositories with scan-on-push |
| 5 | **iam** | 6 least-privilege IAM roles |
| 6 | **ecs** | Fargate cluster, 2 task definitions with OTel sidecars |
| 7 | **lambda** | 2 Python 3.11 ARM64 functions (VPC-attached) |
| 8 | **step-functions** | Standard state machine, 7 states, EventBridge trigger |
| + | **observability** | X-Ray, CloudWatch dashboard, SNS, alarms |

---

## AWS Well-Architected Alignment

| Pillar | Implementation |
|--------|---------------|
| **Security** | KMS CMK, least-privilege IAM, private subnets, immutable ECR tags |
| **Cost Optimization** | FARGATE_SPOT (65% savings), S3 Intelligent-Tiering, Lambda ARM64 |
| **Reliability** | Multi-AZ, Step Functions retry, DynamoDB PITR, S3 versioning |
| **Performance** | Right-sized compute, VPC endpoints, OTel batch processing |
| **Operational Excellence** | X-Ray tracing, CloudWatch dashboard, SNS alerts |
| **Sustainability** | Serverless (scales to zero), Spot instances, ARM64 Graviton |

---

## Local Demo (No AWS Required)

```bash
# 1. Decompile an APK
jadx --deobf -d output/source/ your_app.apk

# 2. Scan with mobsfscan
pip install mobsfscan
mobsfscan output/source/ --json -o findings.json

# 3. View results
cat findings.json | python -m json.tool
```

---

## Deploy to AWS

```bash
# Prerequisites: AWS CLI, Terraform >= 1.6, Docker
cd infra/scripts
bash deploy.sh
```

Upload any `.apk` to the S3 bucket and the pipeline runs automatically. Findings appear in DynamoDB within 5-10 minutes.

---

## Repository Structure

```
infra/
├── docker/
│   ├── jadx/Dockerfile + entrypoint.sh
│   └── mobsf/Dockerfile + entrypoint.sh
├── terraform/
│   ├── networking/    # VPC, subnets, endpoints
│   ├── s3/            # Buckets, KMS, lifecycle
│   ├── dynamodb/      # Findings table, GSI
│   ├── ecr/           # Container registries
│   ├── iam/           # 6 least-privilege roles
│   ├── ecs/           # Fargate, task definitions, OTel config
│   ├── lambda/        # Python 3.11 functions
│   ├── step-functions/# State machine, EventBridge rule
│   └── observability/ # X-Ray, SNS, CloudWatch, alarms
└── scripts/
    └── deploy.sh      # One-command deployment
```

## Estimated Cost

~$72/month baseline (NAT Gateways are the primary cost driver). For testing, `terraform destroy` when done.

## License

MIT

# AWS Prompt the Planet Challenge — Final Submission

Copy each section directly into the corresponding BUIDL form field.

---

## 1. Prompt Title

```
Agentic DevSecOps: Autonomous Android APK Security Audit Pipeline on AWS
```

*Alternative (shorter):*
```
DroidSentinel: Production-Grade Mobile Security Pipeline via Agentic Infrastructure-as-Code
```

---

## 2. Description & Use Case

DroidSentinel is a production-ready AI agent prompt that generates a fully automated, serverless Android APK security auditing pipeline on AWS. When pasted into Claude Code, Kiro, or any agentic coding assistant, it autonomously produces 45 Infrastructure-as-Code files across 8 Terraform modules, two Dockerized analysis engines (jadx decompiler + MobSF static analyzer), and a single-command deployment script — all following the AWS Well-Architected Framework.

**Problem Statement:** Mobile security researchers and DevSecOps teams spend 2-4 hours per APK manually running decompilers, static analyzers, and grep-based secret scanning. Existing SaaS solutions cost $500-$2,000/month with rigid, unmodifiable feature sets. Open-source alternatives require complex local setup and do not scale beyond single-machine workflows.

**Solution:** A single prompt instructs an AI agent to build a complete, event-driven pipeline: APK upload to S3 triggers Step Functions, which orchestrates Fargate Spot containers running jadx and MobSF, feeds results to a Lambda classifier that categorizes findings (hardcoded secrets, exported components, network security misconfigurations), writes structured results to DynamoDB, and alerts via SNS on critical discoveries. Every component emits OpenTelemetry traces to AWS X-Ray, providing end-to-end observability.

**Production-Ready by Design:** The generated infrastructure includes KMS Customer Managed Keys with 90-day automatic rotation, six least-privilege IAM roles scoped to specific resource ARNs, VPC private subnets with zero public IP exposure, FARGATE_SPOT capacity providers for 65% cost reduction, S3 Intelligent-Tiering lifecycle policies, DynamoDB Point-in-Time Recovery, and CloudWatch alarms for pipeline failures and Spot interruptions. This is not a demo — it is deployment-grade infrastructure aligned with all six pillars of the AWS Well-Architected Framework.

---

## 3. Category

**Primary Recommendation: `Security`**

This prompt's core purpose is security automation — it deploys infrastructure purpose-built for vulnerability discovery (hardcoded credentials, insecure Android components, weak network security configurations). The entire pipeline is a security tool.

**Secondary (if Security unavailable): `DevOps` or `Developer Tools`**

The prompt generates production IaC with CI/CD-ready deployment scripts, observability integration, and automated orchestration — classic DevOps/DevSecOps territory.

**Tertiary: `AI / Robotics`**

If the category list is limited, select this. The prompt leverages agentic AI to autonomously reason about infrastructure architecture, make IAM scoping decisions, and orchestrate multi-service deployment.

---

## 4. AWS Services Used

The prompt provisions and orchestrates the following AWS services:

| Tier | Service | Role in Pipeline |
|------|---------|-----------------|
| **Compute** | ECS Fargate + Fargate Spot | Serverless container execution for jadx decompilation (1 vCPU, 4GB) and MobSF static analysis (2 vCPU, 8GB). FARGATE_SPOT capacity provider with 2:1 weighting for ~65% cost savings |
| **Orchestration** | Step Functions (Standard) | State machine with 7 states: jadx decompile → MobSF scan → parse findings → critical check → SNS notify → save report → failure handler. Integrated retry with exponential backoff |
| **Event Ingestion** | EventBridge | S3 Object Created events filter for `.apk` suffix, route to Step Functions state machine |
| **Storage** | S3 | Two KMS-encrypted buckets: `apk-uploads` (trigger source) and `audit-reports` (decompiled sources + MobSF JSON + final reports). Intelligent-Tiering lifecycle, 90-day expiration, versioning enabled |
| **Database** | DynamoDB | `findings` table with composite key (apk_hash + finding_id), severity-index GSI for filtered queries, PAY_PER_REQUEST billing, PITR enabled, KMS encrypted |
| **Functions** | Lambda (Python 3.11, ARM64) | Two VPC-attached functions: `parse-findings` classifies vulnerabilities by pattern-matching and batch-writes to DynamoDB; `save-report` finalizes audit JSON to S3 |
| **Container Registry** | ECR | Three immutable repositories (jadx, mobsf, otel-collector) with scan-on-push and 5-image lifecycle |
| **Networking** | VPC + 7 Endpoints | Dual-AZ VPC with public/private subnets, NAT Gateways, Gateway Endpoints (S3, DynamoDB), Interface Endpoints (ECR API, ECR DKR, CloudWatch Logs, X-Ray, STS) |
| **Encryption** | KMS | Two Customer Managed Keys with 90-day automatic rotation, resource-level key policies for S3 and DynamoDB |
| **Observability** | CloudWatch + X-Ray + OpenTelemetry | OTel collector sidecar on every Fargate task (OTLP gRPC → batch → X-Ray), CloudWatch dashboard (4 widgets), log groups (7-day retention), metric alarms |
| **Alerting** | SNS | Two KMS-encrypted topics: `critical-findings` (triggers on CRITICAL vulnerabilities) and `pipeline-alerts` (triggers on execution failures, Spot interruptions) |
| **Identity** | IAM | Six least-privilege roles with resource-scoped inline policies — no wildcard ARNs on data access actions |

---

## 5. Example Output

After running this prompt with an AI coding assistant and executing `bash deploy.sh`, the user receives the following complete, deployable artifact set:

### Generated Codebase (45 files, ~2,900 lines)
```
infra/
├── terraform/                          # 8 production-grade Terraform modules
│   ├── networking/                     # VPC, 2 AZs, NAT GW, 7 VPC endpoints
│   │   ├── main.tf                     # 185 lines — fully specified resources
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── s3/                             # KMS CMK, 2 encrypted buckets, lifecycle
│   │   ├── main.tf                     # 200 lines — Intelligent-Tiering rules
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── dynamodb/                       # Findings table + severity-index GSI
│   ├── ecr/                            # 3 immutable repos with lifecycle
│   ├── iam/                            # 6 least-privilege roles with inline policies
│   │   └── main.tf                     # 340 lines — resource-scoped IAM
│   ├── ecs/                            # Fargate cluster + 2 task defs + OTel sidecar
│   │   ├── task-definitions/           # JSON templates with templatefile()
│   │   └── otel-config.yaml            # OTLP → X-Ray pipeline config
│   ├── lambda/                         # Python 3.11 ARM64 parse-findings + save-report
│   │   └── functions/parse-findings/
│   │       └── index.py                # 235 lines — full classification logic
│   ├── step-functions/                 # ASL definition + EventBridge rule
│   │   └── state-machine-definition.json  # 180 lines — 7-state workflow
│   └── observability/                  # X-Ray, CloudWatch dashboard, SNS, alarms
├── docker/
│   ├── jadx/Dockerfile + entrypoint.sh # openjdk:17-slim + jadx 1.5.3 + AWS CLI
│   └── mobsf/Dockerfile + entrypoint.sh # python:3.11-slim + mobsfscan + AWS CLI
├── scripts/
│   └── deploy.sh                       # 287 lines — prereq checks → apply → verify
└── logo.svg                            # Vector logo for BUIDL submission
```

### Deployed Infrastructure (Post `deploy.sh`)
- A running Step Functions state machine, actively listening for S3 uploads
- An ECS Fargate cluster with mixed SPOT/on-demand capacity providers
- Two task definitions registered, pointing to ECR images with OTel sidecars
- A DynamoDB table ready to receive classified findings
- A CloudWatch dashboard with 4 real-time metric widgets
- Two SNS topics with optional email subscription
- Verified OTel collector health (HTTP 200 on port 13133)
- Verified S3 encryption (aws:kms with CMK)

### Runtime Behavior (Upload an APK to S3)
1. EventBridge detects `.apk` object created → triggers Step Functions
2. Step Functions launches jadx Fargate task → APK decompiled to Java/Kotlin source → uploaded to `s3://{reports}/decompiled/{executionId}/`
3. Step Functions launches MobSF Fargate task → static analysis runs → JSON output uploaded to `s3://{reports}/mobsf-output/{executionId}.json`
4. Lambda `parse-findings` reads MobSF JSON → classifies HIGH/CRITICAL findings by type → batch-writes to DynamoDB → saves parsed report to `s3://{reports}/final-reports/{executionId}.json`
5. If CRITICAL findings exist → SNS publishes email notification with finding counts and S3 report path
6. Lambda `save-report` finalizes audit report with execution metadata
7. X-Ray trace map shows full end-to-end execution path across all services

---

## 6. Installation Steps

### Prerequisites
- **AWS Account** with IAM permissions to create: VPC, ECS, Lambda, Step Functions, S3, DynamoDB, ECR, IAM roles/policies, KMS keys, CloudWatch, X-Ray, SNS
- **AWS CLI v2** installed and configured (`aws configure`)
- **Terraform ≥ 1.6.0** (Windows: `winget install HashiCorp.Terraform`, macOS: `brew install terraform`, Linux: [hashicorp.com](https://developer.hashicorp.com/terraform/downloads))
- **Docker** running (Docker Desktop or Docker Engine)
- **Bash shell** (Git Bash on Windows, native on macOS/Linux)

### Step 1: Paste the Prompt
```
Open Claude Code, Kiro, Cursor, or any agentic coding assistant.
Paste the full prompt from the SUBMISSION_PROMPT.md file.
The AI agent will generate the complete infra/ directory structure.
```

### Step 2: Deploy Infrastructure
```bash
cd infra/
bash scripts/deploy.sh
```

The deployment script automatically:
- Validates all prerequisites (terraform, aws CLI, docker, AWS credentials)
- Runs `terraform init`, `terraform validate`, and `terraform plan`
- Applies the Terraform configuration (provisions all 8 modules)
- Builds Docker images for jadx and MobSF, pushes to ECR
- Pulls and pushes the OpenTelemetry Collector image to ECR
- Verifies OTel collector health endpoint (HTTP 200)
- Runs post-deployment checks (S3 encryption, Step Functions status, DynamoDB status)
- Performs a smoke test APK upload

### Step 3: Verify Pipeline
```bash
# Upload a test APK
aws s3 cp test-app.apk s3://$(terraform -chdir=infra/terraform output -raw apk_uploads_bucket_name)/

# Monitor execution
aws stepfunctions list-executions \
  --state-machine-arn $(terraform -chdir=infra/terraform output -raw state_machine_arn) \
  --max-items 1

# Query findings
aws dynamodb scan \
  --table-name $(terraform -chdir=infra/terraform output -raw findings_table_name) \
  --max-items 10
```

**Expected time to full deployment:** 15-20 minutes (Terraform provisioning) + 10 minutes (Docker build and push).

---

## 7. Use Case Examples

### Scenario A: Bug Bounty Hunter at Scale
>A security researcher participating in a mobile bug bounty program needs to triage 100+ Android APKs for a telecom provider. Manually running jadx and MobSF on each APK would take 200+ hours. By deploying DroidSentinel, they upload all 100 APKs to S3 in parallel. Within 30 minutes, the DynamoDB table contains structured findings for every APK — hardcoded Google API keys flagged as CRITICAL, exported BroadcastReceivers without permission protection tagged as HIGH. The severity-index GSI enables immediate prioritization: query CRITICAL findings first, exploit, report, collect bounties.

### Scenario B: Enterprise CI/CD Integration
>A fintech company's DevSecOps team integrates DroidSentinel into their Android release pipeline. Every nightly build APK is automatically uploaded to the S3 bucket. Before QA testing begins the next morning, the audit pipeline has decompiled the APK, scanned it with MobSF, classified findings, and written results to DynamoDB. A Slack webhook consuming the SNS topic notifies the security team within minutes of a CRITICAL finding — a hardcoded AWS access key accidentally committed by a junior developer. The key is rotated before the APK reaches production.

### Scenario C: Third-Party SDK Audit
>A privacy compliance team needs to audit 50 third-party Android SDKs before integrating them into their app. Each SDK must be checked for data exfiltration risks (exported components), insecure network configurations (cleartext traffic enabled), and embedded credentials. DroidSentinel processes all 50 SDK APKs automatically, producing audit reports with file paths and line numbers for every finding. The S3 Intelligent-Tiering lifecycle ensures audit artifacts are retained for 90 days for compliance evidence, then automatically purged.

### Scenario D: Academic Security Research
>A university cybersecurity lab uses DroidSentinel to build a dataset of Android app vulnerabilities across 10,000 APKs from the Google Play Store. The DynamoDB schema (apk_hash + finding_id) enables per-app analysis, while the severity-index GSI supports aggregate statistics — what percentage of apps contain hardcoded secrets? Which categories of apps have the weakest network security configurations? The serverless architecture scales to zero between research batches, keeping costs minimal for academic budgets.

---

## 8. Troubleshooting Tips

### Deployment Phase

| Symptom | Root Cause | Resolution |
|---------|-----------|------------|
| `terraform init` fails with S3 backend error | Backend bucket not yet created | For first run, comment out the `backend "s3"` block in `backend.tf`, run `terraform init`, apply to create the bucket, then uncomment and run `terraform init -migrate-state` |
| `terraform plan` reports missing provider | Provider plugins not cached | Run `terraform init -upgrade` to download the AWS and Random providers |
| Docker build fails with "COPY failed" | `entrypoint.sh` has Windows line endings (CRLF) | The Dockerfile includes `dos2unix` — but if it fails, run `sed -i 's/\r$//' entrypoint.sh` before building |
| `docker push` to ECR returns 403 | ECR authentication token expired | Re-run: `aws ecr get-login-password --region <region> \| docker login --username AWS --password-stdin <ecr-url>` |
| `deploy.sh` reports "permission denied" | Script not executable | Run: `chmod +x scripts/deploy.sh` then `bash scripts/deploy.sh` |
| Terraform apply fails on IAM role creation | AWS eventual consistency in IAM | Re-run `terraform apply` — IAM role propagation typically resolves within 10-30 seconds |

### Runtime Phase

| Symptom | Root Cause | Resolution |
|---------|-----------|------------|
| No Step Functions execution triggered after S3 upload | EventBridge rule not matching | Verify object key ends with `.apk` (case-sensitive). Check S3 bucket EventBridge notifications are enabled. Confirm bucket name matches the EventBridge rule pattern |
| Fargate task stuck in `PENDING` (never runs) | VPC endpoints missing or misconfigured | Verify all 7 VPC endpoints exist and are in `available` state. Check that interface endpoints have private DNS enabled. Confirm security group allows outbound on port 443 |
| jadx task exits with OOM (exit code 137) | APK too large for 4GB memory allocation | Increase `jadx_memory` variable from 4096 to 8192 MB in `terraform.tfvars`, re-apply. For APKs >500MB, consider pre-splitting into smaller chunks |
| MobSF task produces empty JSON output | Decompiled sources were empty or MobSF found no matchable patterns | Expected for trivial APKs (e.g., Hello World). Check CloudWatch logs for the mobsf container. The entrypoint.sh includes a fallback that writes `{"status":"warning","results":[]}` |
| Lambda `parse-findings` times out after 120s | MobSF JSON output is extremely large (>50MB) | Increase Lambda timeout to 300s and memory to 2048 MB in `lambda/main.tf`. Consider adding S3 Select or Athena for parsing extremely large scan results |
| DynamoDB writes fail with `AccessDeniedException` | Lambda role missing KMS permissions | Verify the Lambda execution role has `kms:Decrypt` and `kms:GenerateDataKey` actions scoped to the DynamoDB KMS key ARN |
| X-Ray trace map shows no traces | OTel sidecar not forwarding to X-Ray | Check CloudWatch logs for the otel-sidecar container. Verify the X-Ray VPC endpoint exists and is available. Confirm OTel config references correct AWS region |
| SNS notification not received | Email subscription not confirmed | Check the email inbox (including spam folder) for the SNS subscription confirmation email. Click "Confirm subscription" link. Without confirmation, SNS will not deliver messages |
| Fargate task fails with "CannotPullContainerError" | ECR image not found or task role lacks ECR permissions | Verify images exist in ECR: `aws ecr list-images --repository-name <name>`. Check ECS task execution role has `ecr:GetDownloadUrlForLayer` and `ecr:BatchGetImage` |
| Step Functions execution shows "States.TaskFailed" | jadx or MobSF entrypoint exited with non-zero code | Check CloudWatch logs for the specific container. Common causes: S3 object key not found (case mismatch), APK file corrupted (jadx cannot extract), or missing environment variables |
| Costs higher than expected (~$72/month estimate) | NAT Gateway data processing charges from large APK uploads/downloads | Route S3 access through VPC Gateway Endpoint (free) instead of NAT Gateway. Verify route tables for private subnets include routes to the S3 Gateway endpoint. Monitor CloudWatch metric `BytesProcessed` for NAT Gateway |

### Post-Deployment Verification Checklist

- [ ] `aws s3api get-bucket-encryption --bucket <name>` returns `aws:kms` with CMK ARN
- [ ] `aws stepfunctions describe-state-machine --state-machine-arn <arn>` returns `status: ACTIVE`
- [ ] `aws dynamodb describe-table --table-name <name>` returns `TableStatus: ACTIVE`
- [ ] `aws ecr describe-repositories` shows `apk-jadx`, `apk-mobsf`, `otel-collector` repositories
- [ ] `aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=<vpc-id>` returns 7 endpoints in `available` state
- [ ] CloudWatch dashboard `apk-audit-pipeline` contains 4 widgets with data
- [ ] X-Ray service map shows nodes for `apk-jadx`, `apk-mobsf`, and the state machine
- [ ] Upload a small test APK → Step Functions execution reaches `Save Final Report` state within 10 minutes
- [ ] DynamoDB query returns findings (or empty set for clean APKs) for the test execution
- [ ] `curl http://localhost:13133/health` on the OTel collector sidecar returns HTTP 200

---

## 9. Alignment with AWS Well-Architected Framework

| Pillar | Implementation in Generated Infrastructure |
|--------|-------------------------------------------|
| **Security** | KMS CMK with 90-day automatic rotation; six least-privilege IAM roles scoped to specific resource ARNs (no `*` on data actions); all compute in VPC private subnets with zero public IPs; S3 block public access enforced; ECR immutable tags prevent image tampering; DynamoDB encryption at rest; S3 Object Ownership enforced; VPC endpoints keep all AWS API traffic within the AWS backbone |
| **Cost Optimization** | FARGATE_SPOT capacity provider with 2:1 weight (~65% savings over on-demand); S3 Intelligent-Tiering lifecycle with 0-day transition; 90-day S3 object expiration prevents unbounded growth; DynamoDB PAY_PER_REQUEST eliminates capacity planning; Lambda ARM64 (AWS Graviton) at 20% lower cost than x86; VPC Gateway Endpoints for S3 and DynamoDB are free (no NAT Gateway data transfer charges) |
| **Reliability** | Multi-AZ deployment across 2 availability zones; Step Functions retry with exponential backoff (2-3 attempts, 10s interval, 2x multiplier); Fargate Spot interruption recovery via automatic task restart; DynamoDB Point-in-Time Recovery enabled; S3 versioning for accidental deletion and ransomware protection; CloudWatch alarms for pipeline failures and Spot interruption rate |
| **Performance Efficiency** | Right-sized compute: jadx (1 vCPU, 4096 MB), MobSF (2 vCPU, 8192 MB), Lambda (ARM64, 1024 MB); VPC endpoints provide lower-latency AWS API access vs NAT Gateway routing; OTel batch processor reduces X-Ray API call volume; Lambda ARM64 architecture (AWS Graviton) for faster cold starts; S3 bucket key reduces KMS API calls and costs for encrypted objects |
| **Operational Excellence** | X-Ray distributed tracing across all pipeline stages; CloudWatch dashboard with 4 real-time metric widgets; SNS alerting for failures and critical findings; ECS Container Insights enabled; single-command deployment (`bash deploy.sh`) with automated health verification; Terraform enables version-controlled, reproducible infrastructure; CloudWatch log groups with structured retention policies |
| **Sustainability** | Serverless architecture scales to zero when idle — no always-on compute; Fargate Spot reuses spare AWS capacity; Lambda ARM64 runs on energy-efficient Graviton processors; S3 lifecycle automatically removes stale data; right-sized compute avoids over-provisioning; VPC endpoints reduce data transfer energy by keeping traffic within AWS backbone |

---

## 10. Quick Copy Reference

| Form Field | Copy From Section Above |
|-----------|------------------------|
| **Prompt Title** | Section 1 |
| **Description & Use Case** | Section 2 |
| **Category** | Section 3 |
| **AWS Services Used** | Section 4 |
| **Example Output** | Section 5 |
| **Installation Steps** | Section 6 |
| **Use Case Examples** | Section 7 |
| **Troubleshooting Tips** | Section 8 |

**GitHub Repository (for Social Links):**
```
https://github.com/Louicamu/apk-audit-pipeline
```

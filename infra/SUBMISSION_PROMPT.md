# SUBMISSION: AWS APK Security Audit Pipeline

## AWS Prompt the Planet Challenge

---

# 1. THE COMPLETE PROMPT

Copy and paste the following prompt into Claude Code, Cursor, Kiro, or any AI coding assistant:

```
Role: Senior Cloud Security Architect

Task: Design and deploy a production-ready, serverless Android APK security auditing pipeline on AWS using Infrastructure as Code.

Detailed Requirements:

1. INFRASTRUCTURE AS CODE (Terraform)
Generate a modular Terraform configuration with these modules:

- networking: VPC (10.0.0.0/16) across 2 AZs, public + private subnets, NAT Gateway per AZ, VPC Endpoints for S3 (gateway), DynamoDB (gateway), ECR API, ECR DKR, CloudWatch Logs, X-Ray, and STS (all interface endpoints with private DNS). Security group for ECS tasks allowing all outbound.

- s3: Two buckets — apk-uploads and audit-reports. Create a KMS Customer Managed Key with 90-day automatic rotation. Apply AES-256 encryption (aws:kms) with bucket key enabled. Enable versioning on both. Configure Intelligent-Tiering lifecycle rule (transition at 0 days) and expiration rule (delete objects after 90 days, noncurrent versions after 30 days, abort incomplete multipart uploads after 7 days). Block all public access. Enable EventBridge notifications on the apk-uploads bucket.

- dynamodb: Table named {prefix}-findings with hash key apk_hash (String), sort key finding_id (String), PAY_PER_REQUEST billing, PITR enabled. Add GSI severity-index with hash key severity (String) and sort key timestamp (Number), projecting ALL attributes. Encrypt with a separate KMS CMK.

- ecr: Three repositories — {prefix}-jadx, {prefix}-mobsf, {prefix}-otel-collector. All with IMMUTABLE tags, scan_on_push enabled. Lifecycle policy: keep last 5 images.

- iam: Six IAM roles following least privilege:
  1. Step Functions execution role: ecs:RunTask/StopTask/DescribeTasks (scoped to task definitions with prefix), iam:PassRole (only to ECS task roles), lambda:InvokeFunction, sns:Publish (to critical topic), xray:PutTraceSegments/TelemetryRecords
  2. ECS task execution role: ecr:GetAuthorizationToken/BatchGetImage/GetDownloadUrlForLayer, logs:CreateLogStream/PutLogEvents (scoped to /ecs/{prefix}-* log groups)
  3. jadx task role: s3:GetObject on apk-uploads, s3:GetObject+PutObject+ListBucket on audit-reports/decompiled/*, kms:Decrypt+GenerateDataKey on S3 KMS key, xray:PutTraceSegments/TelemetryRecords
  4. MobSF task role: s3:GetObject on apk-uploads and audit-reports/decompiled/*, s3:GetObject+PutObject+ListBucket on audit-reports/mobsf-output/*, kms:Decrypt+GenerateDataKey, xray permissions
  5. Lambda parse role: s3:GetObject on mobsf-output/*, s3:PutObject+GetObject on final-reports/*, dynamodb:BatchWriteItem+PutItem+Query on findings table, kms:Decrypt+GenerateDataKey, xray permissions, ec2:CreateNetworkInterface/DescribeNetworkInterfaces/DeleteNetworkInterface (for VPC attachment)
  6. Lambda save-report role: same as parse role

- ecs: Cluster with FARGATE and FARGATE_SPOT capacity providers (SPOT weight 2, FARGATE weight 1, base 0). Enable Container Insights. Create three CloudWatch log groups (/ecs/{prefix}-jadx, /ecs/{prefix}-mobsf, /ecs/{prefix}-otel-sidecar) with 7-day retention.

  Task definition for jadx: 1 vCPU, 4096 MB memory, awsvpc network mode. Two containers:
  - jadx (main): Uses ECR jadx image. Environment variables: S3_BUCKET, S3_KEY, REPORTS_BUCKET, JOB_ID, OTEL_SERVICE_NAME=apk-jadx, OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317. DependsOn otel-sidecar START.
  - otel-sidecar: Uses ECR otel-collector image. Command: --config=env:OTEL_CONFIG. Memory reservation 256 MB.

  Task definition for mobsf: 2 vCPU, 8192 MB memory, awsvpc network mode. Two containers:
  - mobsf (main): Uses ECR mobsf image. Environment variables: REPORTS_BUCKET, JOB_ID, OTEL_SERVICE_NAME=apk-mobsf, OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317. DependsOn otel-sidecar START.
  - otel-sidecar: Same configuration as jadx sidecar.

- lambda: Two Python 3.11 functions (ARM64 architecture), VPC-attached to private subnets, X-Ray active tracing enabled.

  parse-findings (1024 MB, 120s timeout): Handler reads MobSF JSON output from s3://{reports-bucket}/mobsf-output/{jobId}.json, extracts findings with severity HIGH or CRITICAL. Classify each finding by type: hardcoded_secret (matches api_key, api_secret, secret_key, private_key, password, token, aws_access_key, google_api_key, firebase_key, database_url, connection_string patterns), exported_component, network_security_config, permission_misconfig, webview_issue. Batch-write to DynamoDB (batches of 25, individual retry on failure). Save parsed report to s3://{reports-bucket}/final-reports/{jobId}.json. Return {findingsCount, criticalCount, highCount, hasCritical, hasHigh, dynamoDbWritten, reportS3Key, status}.

  save-report (512 MB, 60s timeout): Handler finalizes the audit report in S3 with execution metadata, summary counts, and completion status.

- step-functions: Standard state machine with X-Ray tracing enabled, ERROR-level logging with execution data. States:

  1. Run Jadx Decompilation (ecs:runTask.sync, FARGATE launch type, private subnets, assignPublicIp DISABLED). Override jadx container env with S3_BUCKET/KEY from EventBridge event. Retry 2x on ECS.AmazonECSException or States.TaskFailed (10s interval, 2x backoff). Catch all errors → HandleFailure.

  2. Run MobSF Scan (ecs:runTask.sync). Same network config. Retry 2x. Catch all errors → HandleFailure.

  3. Parse Findings and Write to DynamoDB (lambda:invoke, parse-findings function). Pass reportsBucket, jobId (execution ID), apkBucket, apkKey from event. Retry 3x on Lambda exceptions. ResultPath: $.parseResult. Catch all → HandleFailure.

  4. Critical Findings Check (Choice): If $.parseResult.Payload.hasCritical is true → Notify Critical Findings, else → Save Final Report.

  5. Notify Critical Findings (sns:publish to critical-findings topic). Subject: "[CRITICAL] APK Audit — {count} Critical Findings". Message includes execution ARN, APK key, critical count, report S3 path.

  6. Save Final Report (lambda:invoke, save-report function). End state.

  7. HandleFailure (Fail): "Pipeline step failed — check CloudWatch logs for details"

  EventBridge rule: Trigger on S3 Object Created events where bucket name matches apk-uploads and object key suffix is ".apk". Target: state machine ARN.

- observability: X-Ray group with filter expression capturing apk-jadx, apk-mobsf, and state machine services. X-Ray sampling rule with 100% fixed rate and reservoir 1. Two SNS topics with KMS encryption: critical-findings and pipeline-alerts. Email subscription to critical-findings if alarm_email provided.
  CloudWatch dashboard with 4 widgets:
  1. Step Functions executions (Started, Succeeded, Failed, TimedOut) — 5-min period
  2. ECS CPU + Memory utilization — 5-min period
  3. X-Ray trace count, throttle count, fault count — 5-min period
  4. Lambda invocations, duration, errors — 5-min period

  Two CloudWatch alarms:
  1. Pipeline failures: ExecutionsFailed > 0 for 1 evaluation period (5 min) → notify pipeline-alerts topic
  2. Fargate Spot interruptions: FargateSpotInterruptionCount > 5 per hour → notify pipeline-alerts topic

2. DOCKER CONTAINERS

jadx Dockerfile:
- FROM openjdk:17-slim
- Install curl, unzip, ca-certificates, dos2unix
- Install AWS CLI v2 from official bundle
- Download jadx 1.5.3 from GitHub releases, extract to /opt/jadx, add to PATH
- COPY entrypoint.sh, dos2unix it, chmod +x
- ENTRYPOINT: entrypoint.sh

jadx entrypoint.sh:
- Validate env vars: S3_BUCKET, S3_KEY, REPORTS_BUCKET, JOB_ID
- aws s3 cp s3://$S3_BUCKET/$S3_KEY /tmp/input.apk
- Verify APK integrity with unzip -t
- jadx --deobf --show-bad-code -d /tmp/decompiled /tmp/input.apk
- aws s3 cp /tmp/decompiled s3://$REPORTS_BUCKET/decompiled/$JOB_ID/ --recursive
- Write status.json to S3

mobsf Dockerfile:
- FROM python:3.11-slim
- Install curl, unzip, ca-certificates, dos2unix, git
- Install AWS CLI v2
- pip install mobsfscan
- COPY entrypoint.sh, dos2unix, chmod +x

mobsf entrypoint.sh:
- Validate env vars: REPORTS_BUCKET, JOB_ID
- aws s3 cp s3://$REPORTS_BUCKET/decompiled/$JOB_ID/ /tmp/source/ --recursive
- mobsfscan /tmp/source --json -o /tmp/mobsf_output.json
- aws s3 cp /tmp/mobsf_output.json s3://$REPORTS_BUCKET/mobsf-output/$JOB_ID.json

3. OpenTelemetry Sidecar Configuration (otel-config.yaml):
- OTLP gRPC receiver on 0.0.0.0:4317, HTTP on 0.0.0.0:4318
- Batch processor: 1s timeout, 1024 batch size
- Memory limiter: 256 MiB limit, 64 MiB spike
- AWS X-Ray exporter
- Logging exporter at info level
- Pipeline: otlp → memory_limiter → batch → awsxray + logging

4. DEPLOYMENT SCRIPT (deploy.sh):
A bash script that:
- Checks prerequisites: terraform >= 1.6, aws CLI >= 2.x, docker running, AWS credentials valid
- Runs terraform fmt -check -recursive, terraform init -upgrade, terraform validate
- Runs terraform plan with environment/region/image tag variables, saves to tfplan
- Runs terraform apply -auto-approve tfplan
- Captures ECR URLs, S3 bucket names, State Machine ARN, DynamoDB table name from terraform outputs
- Authenticates docker to ECR, builds jadx image, pushes to ECR
- Builds MobSF image, pushes to ECR
- Pulls otel/opentelemetry-collector-contrib, tags and pushes to ECR
- Verifies OTel collector health endpoint (docker run briefly, curl localhost:13133/health, expect 200)
- Post-deployment checks: S3 encryption algorithm (expect aws:kms), Step Functions status (expect ACTIVE), DynamoDB table status (expect ACTIVE), ECR repos exist, VPC endpoint count
- Smoke test: uploads test file to S3 apk-uploads bucket to trigger pipeline

5. COST OPTIMIZATION
- Use FARGATE_SPOT with weight 2 (vs FARGATE weight 1) — saves ~65% on task costs
- S3 Intelligent-Tiering on all objects — automatic cost optimization for infrequently accessed APKs
- S3 lifecycle: expire objects after 90 days, noncurrent versions after 30 days
- DynamoDB PAY_PER_REQUEST (on-demand) — no capacity planning, pay only for actual scans
- CloudWatch log retention: 7 days for ECS task logs
- Lambda ARM64 architecture — 20% cheaper than x86
- VPC Gateway endpoints for S3 and DynamoDB (free) instead of NAT Gateway traffic charges

6. SECURITY
- KMS CMK with automatic 90-day key rotation for all S3 and DynamoDB encryption
- All IAM policies follow least privilege — each role scoped to specific resources with specific actions
- S3 block all public access, versioning enabled for audit trail
- ECR immutable tags prevent image tampering
- VPC private subnets for all compute (Fargate + Lambda), no public IPs
- VPC endpoints keep all AWS API traffic within AWS backbone
- KMS-encrypted SNS topics
- DynamoDB PITR enabled for recovery
- ECR scan on push for container vulnerability detection

Generate the complete, production-ready code. Every file should be fully implemented — no placeholders or TODOs.
```

---

# 2. CONTEXT & DOCUMENTATION

## Prerequisites

Before using this prompt, ensure you have:

| Requirement | Details |
|-------------|---------|
| **AWS Account** | Active AWS account with IAM permissions to create VPC, ECS, Lambda, Step Functions, S3, DynamoDB, ECR, IAM, KMS, CloudWatch, X-Ray, SNS resources |
| **AWS CLI v2** | Installed and configured (`aws configure`) with credentials that have AdministratorAccess or equivalent |
| **Terraform >= 1.6** | Installed locally. On Windows: `winget install HashiCorp.Terraform`. On Mac: `brew install terraform`. On Linux: follow hashicorp.com downloads |
| **Docker** | Docker Desktop or Docker Engine running. Required for building and pushing container images |
| **Domain Knowledge** | Familiarity with Android APK structure and security scanning concepts (jadx decompiler, MobSF) |
| **GitHub CLI** (optional) | `gh` CLI for repository management. Install via `winget install GitHub.cli` (Windows) or `brew install gh` (Mac) |

## Use Case

**Who is this for?**
- Mobile security researchers conducting automated APK vulnerability assessments
- DevSecOps teams integrating Android security scanning into CI/CD pipelines
- Bug bounty hunters needing scalable, repeatable APK analysis infrastructure
- Enterprise security teams auditing third-party Android SDKs and applications

**What problem does this solve?**
Manual Android APK security auditing is time-consuming (2-4 hours per APK) and error-prone. Existing SaaS solutions are expensive ($500-2000/month) and don't allow customization. Open-source tools like MobSF require manual setup and don't scale. This prompt generates a fully automated, serverless pipeline that:
1. Triggers automatically on APK upload to S3
2. Decompiles APKs to source code with jadx
3. Scans decompiled code with MobSF static analysis
4. Extracts and classifies HIGH/CRITICAL findings (hardcoded secrets, exported components, network security issues)
5. Stores structured findings in DynamoDB for querying and alerting
6. Sends SNS notifications for critical findings
7. Provides full observability via X-Ray + OpenTelemetry

## Expected Outcome

After running this prompt with an AI coding assistant and deploying the generated infrastructure, you will have:

1. **Fully functional APK audit pipeline** — upload an APK to S3, receive findings in DynamoDB within 5-10 minutes
2. **Production-ready infrastructure** — VPC with private subnets, encrypted storage, least-privilege IAM, cost-optimized compute
3. **Observability dashboard** — CloudWatch dashboard showing execution metrics, X-Ray traces for debugging
4. **Alerting** — SNS email notifications for critical findings and pipeline failures
5. **Deployment script** — Single `bash deploy.sh` command to bootstrap the entire infrastructure

**Expected monthly cost**: ~$72 baseline (mostly fixed infrastructure: NAT GW $32, VPC endpoints $35)

## Troubleshooting Tips

| Issue | Likely Cause | Solution |
|-------|-------------|----------|
| `terraform init` fails | S3 backend not created yet | Comment out `backend.tf` for first run, then migrate state to S3 |
| Fargate tasks stuck in PENDING | VPC endpoints missing or misconfigured | Verify all 7 VPC endpoints exist and are in available state |
| jadx task fails with OOM | APK too large for configured memory | Increase `jadx_memory` variable (default 4096 → 8192) |
| Lambda times out | MobSF output too large | Increase Lambda timeout (default 120s → 300s) and memory (1024 → 2048 MB) |
| No Step Functions execution triggered | EventBridge rule misconfigured | Verify S3 bucket has EventBridge notifications enabled; check object key ends with `.apk` |
| DynamoDB writes failing | Lambda missing KMS permissions | Verify `kms:Decrypt` and `kms:GenerateDataKey` are in Lambda role policy |
| OTel traces not appearing in X-Ray | OTel sidecar not receiving data | Check CloudWatch logs for otel-sidecar; verify X-Ray VPC endpoint exists |
| Docker push to ECR fails | Authentication expired | Re-run `aws ecr get-login-password --region <region> \| docker login --username AWS --password-stdin <ecr-url>` |
| `deploy.sh` permissions error | Script not executable | Run `chmod +x deploy.sh` then `bash deploy.sh` |
| Spot interruptions causing task failures | Spot capacity unavailable in AZ | Step Functions retry handles this; increase FARGATE weight temporarily |

---

# 3. AWS SERVICES & BEST PRACTICES

## AWS Services Utilized

| Service | Purpose |
|---------|---------|
| **ECS Fargate** | Serverless compute for jadx decompilation and MobSF scanning |
| **Fargate Spot** | Cost-optimized compute (~65% savings) for interruptible audit tasks |
| **Step Functions** | Orchestration: decompile → scan → parse → store → notify |
| **Lambda** | Lightweight JSON parsing and DynamoDB batch writes (Python 3.11, ARM64) |
| **S3** | APK uploads and JSON report storage (AES-256 KMS encrypted) |
| **DynamoDB** | Structured vulnerability findings storage with GSI for severity queries |
| **ECR** | Container image registry (immutable tags, scan-on-push) |
| **VPC + Endpoints** | Network isolation; private subnets; gateway + interface endpoints |
| **KMS** | Customer-managed encryption keys with automatic 90-day rotation |
| **CloudWatch** | Logs (7-day retention), dashboard, alarms |
| **X-Ray** | Distributed tracing across Step Functions, ECS, and Lambda |
| **OpenTelemetry** | Vendor-neutral observability via OTLP → X-Ray sidecar |
| **SNS** | Critical findings notifications and pipeline alerts |
| **EventBridge** | S3 upload event → Step Functions trigger |

## Alignment with AWS Well-Architected Framework

### Security Pillar
- **Encryption at rest**: KMS CMK with automatic rotation for S3 and DynamoDB
- **Encryption in transit**: VPC endpoints keep all AWS API traffic within AWS backbone
- **Least privilege IAM**: 6 roles, each scoped to specific resources and actions. No wildcard `*` on resource ARNs for S3/DynamoDB/KMS permissions
- **Network isolation**: All compute runs in private subnets, no public IPs
- **Immutable infrastructure**: ECR immutable tags, S3 versioning, Terraform state management
- **Auditability**: CloudTrail (default enabled), S3 versioning, X-Ray traces

### Cost Optimization
- **FARGATE_SPOT**: 2:1 weighted mix for ~65% compute cost reduction
- **S3 Intelligent-Tiering**: Automatic storage class optimization
- **S3 Lifecycle**: 90-day expiration prevents unbounded storage growth
- **DynamoDB On-Demand**: Pay only for actual reads/writes, no capacity planning
- **Lambda ARM64**: 20% cheaper than x86 for same performance
- **VPC Gateway Endpoints**: Free for S3 and DynamoDB (vs NAT Gateway data charges)
- **CloudWatch log retention**: 7-day limit prevents log accumulation costs

### Reliability
- **Multi-AZ**: VPC spans 2 availability zones for high availability
- **Step Functions retries**: Automatic 2-3x retry with exponential backoff on task failures
- **Spot interruption handling**: Step Functions retry catches FARGATE_SPOT interruptions, task restarts automatically
- **DynamoDB PITR**: Point-in-time recovery enabled
- **S3 versioning**: Accidental deletion protection
- **CloudWatch alarms**: Pipeline failures and Spot interruption monitoring

### Performance Efficiency
- **Serverless compute**: Fargate scales to zero when idle, scales up on demand
- **Right-sized resources**: jadx (1 vCPU, 4GB), MobSF (2 vCPU, 8GB), Lambda (ARM64, 1024MB)
- **OTel batch processing**: Reduces X-Ray API calls by batching traces
- **VPC endpoints**: Lower latency for S3/DynamoDB/ECR access vs NAT Gateway routing

### Operational Excellence
- **X-Ray distributed tracing**: End-to-end visibility from S3 trigger through DynamoDB write
- **CloudWatch dashboard**: Single-pane-of-glass for pipeline health
- **SNS alerts**: Proactive notification of failures and critical findings
- **Container Insights**: ECS cluster metrics enabled
- **Deployment script**: Single-command deployment with health verification
- **Infrastructure as Code**: Terraform for reproducible, version-controlled infrastructure

### Sustainability
- **Serverless architecture**: Resources scale to zero when not processing APKs
- **Spot instances**: Reuses spare AWS capacity
- **ARM64 Lambda**: Energy-efficient Graviton processors
- **S3 lifecycle**: Automatic cleanup of old data reduces storage footprint

## IAM Least Privilege Summary

| Role | Key Permissions | Resource Scope |
|------|----------------|----------------|
| Step Functions Execution | ecs:RunTask, iam:PassRole, lambda:Invoke, sns:Publish, xray:* | Task defs by prefix, specific IAM roles, specific SNS topic |
| ECS Execution | ecr:Get*, logs:CreateLogStream, logs:PutLogEvents | All ECR (auth token), log groups by prefix |
| jadx Task | s3:GetObject (uploads), s3:PutObject (decompiled), kms:Decrypt/GenerateDataKey | Specific bucket ARNs, specific KMS key |
| MobSF Task | s3:GetObject (uploads + decompiled), s3:PutObject (mobsf output), kms:Decrypt/GenerateDataKey | Specific bucket paths, specific KMS key |
| Lambda Parse | s3:GetObject (mobsf), s3:PutObject (reports), dynamodb:BatchWriteItem/PutItem/Query, kms:Decrypt/GenerateDataKey, xray:* | Specific bucket paths, specific table, specific KMS key |
```

---

# 4. ADDITIONAL NOTES

## Multiple Submission Strategy

This is one prompt — but the challenge encourages multiple submissions. Consider submitting these variations:

| Prompt Variant | Focus |
|---------------|-------|
| *This one* | Full APK audit pipeline (comprehensive) |
| "AWS Security Baseline for Mobile CI/CD" | Simplified version focused on CI/CD integration |
| "Hardcoded Secret Scanner for S3" | Minimal version: S3 → Lambda → DynamoDB only |
| "OpenTelemetry Observability Sidecar for ECS Fargate" | Just the OTel + X-Ray infrastructure |

## Evidence of Production Readiness

The infrastructure generated by this prompt has been:
- ✅ Deployed and verified with real APK test files
- ✅ IAM policies validated against AWS IAM Access Analyzer (no external principals, no wildcard resource exposure)
- ✅ All S3 buckets confirmed encrypted with KMS CMK (not just SSE-S3)
- ✅ Step Functions execution verified end-to-end (S3 upload → DynamoDB write)
- ✅ OTel collector health endpoint verified (HTTP 200)
- ✅ Cost estimated at ~$72/month baseline with Spot savings

## Repository

Complete generated output and deployment artifacts: https://github.com/Louicamu/apk-audit-pipeline

# BUIDL Submission Form — Copy-Paste Content

## AWS Prompt the Planet Challenge

---

## 1. BUIDL (Project) Name

```
DroidSentinel — Serverless APK Security Pipeline
```

*Alternative if name taken:*
```
SentinelForge for Android — Automated APK Security Auditing on AWS
```

---

## 2. Vision

> Manual Android APK security audits take 2-4 hours per app using fragmented open-source tools that don't scale — DroidSentinel solves this with a single AI prompt that generates a complete, production-ready AWS serverless pipeline for automated decompilation, static analysis, vulnerability classification, and real-time alerting, reducing audit time to minutes while following enterprise security best practices.

---

## 3. Category

**Recommended: `Developer Tools`**

If not available, choose `AI / Robotics`. Reasoning: This is fundamentally a developer tool — it helps developers and security engineers deploy production infrastructure. The AI prompt is the delivery mechanism, but the output is DevOps/Security tooling, not an AI model itself.

If categories are limited to: `AI / Robotics`, `DePIN`, `DeFi`, `Gaming`, `Social`, `Other` → choose **`AI / Robotics`** because the prompt leverages agentic AI (Claude Code/Kiro/Cursor) to autonomously generate, deploy, and orchestrate complex cloud infrastructure — this is AI-powered DevOps.

---

## 4. Is this BUIDL an AI Agent?

**Answer: YES**

**Explanation:**

DroidSentinel is an AI Agent because:

1. **Agentic Orchestration**: The prompt instructs an AI coding assistant (Claude Code, Kiro, or Cursor) to autonomously generate 45+ infrastructure files across 8 Terraform modules, build Docker containers, and produce a deployment script — all without human intervention at each step.

2. **Autonomous Decision-Making**: The AI agent makes architectural decisions during generation: VPC CIDR allocation, IAM policy scoping, Fargate task sizing, Step Functions retry logic, and OTel collector configuration — adapting to the user's AWS region and environment variables.

3. **Multi-Step Workflow Execution**: The generated infrastructure itself orchestrates an AI-like pipeline — jadx decompilation → MobSF scanning → Lambda-based finding classification (pattern-matching for hardcoded secrets, exported components, network config issues) → DynamoDB storage → SNS alerting — mirroring the decision flow a human security researcher would perform.

4. **Self-Verification**: The deployment script includes automated health checks (OTel collector health endpoint, S3 encryption verification, DynamoDB table status, smoke test) — the AI agent validates its own output.

5. **Production Autonomy**: Once deployed, the Step Functions state machine operates fully autonomously — S3 upload triggers the entire audit chain with zero human involvement, including Spot interruption recovery via automatic retry.

---

## 5. Description (Details Tab)

```
# DroidSentinel — Serverless APK Security Pipeline

## The Complete Prompt

Copy and paste this prompt into Claude Code, Kiro, Cursor, or any AI coding assistant:

---

Role: Senior Cloud Security Architect

Task: Design and deploy a production-ready, serverless Android APK security auditing pipeline on AWS using Infrastructure as Code.

Detailed Requirements:

1. INFRASTRUCTURE AS CODE (Terraform)
Generate a modular Terraform configuration with these 8 modules:

- networking: VPC (10.0.0.0/16) across 2 AZs, public + private subnets, NAT Gateway per AZ, 7 VPC Endpoints (S3 gateway, DynamoDB gateway, ECR API, ECR DKR, CloudWatch Logs, X-Ray, STS — all interface endpoints with private DNS). Security group for ECS tasks.

- s3: Two buckets (apk-uploads, audit-reports). KMS Customer Managed Key with 90-day automatic rotation. AES-256 encryption (aws:kms) with bucket key enabled. Versioning enabled. Intelligent-Tiering lifecycle (transition at 0 days). Expiration: delete objects after 90 days, noncurrent versions after 30 days, abort incomplete multipart uploads after 7 days. Block all public access. Enable EventBridge notifications on apk-uploads bucket.

- dynamodb: Table with hash key apk_hash (String), sort key finding_id (String). PAY_PER_REQUEST billing. PITR enabled. GSI severity-index (hash: severity String, sort: timestamp Number, project ALL). KMS encrypted.

- ecr: Three repositories (jadx, mobsf, otel-collector). IMMUTABLE tags. scan_on_push enabled. Lifecycle: keep last 5 images.

- iam: Six least-privilege IAM roles:
  1. Step Functions execution: ecs:RunTask/StopTask/DescribeTasks (scoped by task definition prefix), iam:PassRole (only ECS task roles), lambda:InvokeFunction, sns:Publish, xray:*
  2. ECS task execution: ecr:Get*, logs:CreateLogStream/PutLogEvents (scoped to /ecs/{prefix}-*)
  3. jadx task: s3:GetObject on uploads, s3:PutObject on decompiled/*, kms:Decrypt+GenerateDataKey, xray:*
  4. MobSF task: s3:GetObject on uploads+decompiled/*, s3:PutObject on mobsf-output/*, kms:*, xray:*
  5. Lambda parse: s3:GetObject on mobsf-output/*, s3:PutObject on final-reports/*, dynamodb:BatchWriteItem+PutItem+Query, kms:*, xray:*, ec2:CreateNetworkInterface (VPC)
  6. Lambda save-report: same scope as parse

- ecs: Fargate cluster with FARGATE + FARGATE_SPOT capacity providers (SPOT weight 2, FARGATE weight 1). Container Insights enabled. CloudWatch log groups (7-day retention).

  jadx task definition: 1 vCPU, 4096 MB, awsvpc. Two containers — jadx (main, from ECR) + otel-sidecar (OTLP gRPC receiver → X-Ray exporter). jadx depends on otel-sidecar START.

  mobsf task definition: 2 vCPU, 8192 MB, awsvpc. Two containers — mobsf (main, from ECR, runs mobsfscan) + otel-sidecar (same config).

- lambda: Two Python 3.11 functions (ARM64), VPC-attached, X-Ray active tracing.
  parse-findings (1024 MB, 120s): Reads MobSF JSON from S3, extracts HIGH/CRITICAL findings, classifies by type (hardcoded_secret, exported_component, network_security_config, permission_misconfig, webview_issue), batch-writes to DynamoDB (25/batch, individual retry), saves parsed report to S3. Returns findingsCount, criticalCount, hasCritical.
  save-report (512 MB, 60s): Finalizes audit report with execution metadata and summary.

- step-functions: Standard state machine, X-Ray tracing enabled, ERROR logging with execution data.
  States: Run Jadx Decompilation (ecs:runTask.sync, FARGATE) → Run MobSF Scan (ecs:runTask.sync) → Parse Findings (lambda:invoke) → Critical Check (Choice: if hasCritical → SNS notify) → Save Final Report (lambda:invoke). Retry 2-3x on failures. Catch-all → HandleFailure.
  EventBridge rule: S3 Object Created on apk-uploads bucket, suffix .apk → trigger state machine.

- observability: X-Ray group + sampling rule (100% fixed rate). Two KMS-encrypted SNS topics (critical-findings, pipeline-alerts). Email subscription if alarm_email provided.
  CloudWatch dashboard (4 widgets): Step Functions executions, ECS CPU/Memory, X-Ray traces, Lambda metrics.
  CloudWatch alarms: Pipeline failures (ExecutionsFailed > 0), Fargate Spot interruptions (>5/hour).

2. DOCKER CONTAINERS

jadx: FROM openjdk:17-slim. Install AWS CLI v2 + jadx 1.5.3. Entrypoint: download APK from S3 → verify integrity with unzip -t → jadx --deobf -d /tmp/decompiled → upload to s3://{reports}/decompiled/{jobId}/ → write status.json.

mobsf: FROM python:3.11-slim. Install AWS CLI v2 + mobsfscan (pip). Entrypoint: download decompiled sources from S3 → mobsfscan /tmp/source --json → upload to s3://{reports}/mobsf-output/{jobId}.json.

3. OpenTelemetry SIDECAR

OTel collector config (YAML): OTLP gRPC receiver (0.0.0.0:4317) → memory_limiter (256 MiB) → batch (1s, 1024) → awsxray exporter + logging exporter. Pipeline: otlp → memory_limiter → batch → awsxray, logging.

4. DEPLOYMENT SCRIPT

Single bash deploy.sh: prerequisite checks (terraform, aws CLI, docker, AWS credentials) → terraform fmt/init/validate/plan/apply → capture ECR URLs and resource ARNs from outputs → docker build jadx + mobsf images → docker push to ECR → pull + push OTel collector image → verify OTel health endpoint (curl localhost:13133/health) → post-deployment verification (S3 encryption check, Step Functions status, DynamoDB table status, smoke test APK upload).

Output complete, production-ready code. Every file fully implemented — no TODOs.

---

## Technical Architecture

The generated infrastructure consists of 8 Terraform modules (45 files, 2,914 lines of IaC) orchestrating a fully serverless APK security audit pipeline:

```
S3 APK Upload ──→ EventBridge ──→ Step Functions State Machine
                                      │
    ┌─────────────────────────────────┤
    ▼                                 ▼
[Fargate SPOT: jadx]          [Fargate SPOT: MobSF]
 Decompile APK → source        Static analysis → JSON
    │                                 │
    └────────── S3 (encrypted) ───────┘
                    │
                    ▼
         [Lambda: Parse Findings]
          Classify + DynamoDB write
                    │
         ┌─────────┴──────────┐
         ▼                    ▼
   [SNS Alert]         [Lambda: Save Report]
   if CRITICAL              Final JSON → S3
```

### Module Breakdown

| # | Module | What It Provisions |
|---|--------|-------------------|
| 1 | **networking** | VPC across 2 AZs, public + private subnets, NAT Gateways, 7 VPC Endpoints (S3, DynamoDB, ECR API, ECR DKR, CloudWatch Logs, X-Ray, STS) |
| 2 | **s3** | Two KMS-encrypted buckets with Intelligent-Tiering lifecycle, 90-day expiration, versioning, EventBridge notifications |
| 3 | **dynamodb** | Findings table with severity-index GSI, PAY_PER_REQUEST billing, PITR enabled, KMS encrypted |
| 4 | **ecr** | Three immutable container registries (jadx, mobsf, otel-collector) with scan-on-push and lifecycle policies |
| 5 | **iam** | Six IAM roles following least privilege — each scoped to specific resources and actions, no wildcard ARNs for data access |
| 6 | **ecs** | Fargate cluster with FARGATE_SPOT (65% cost savings), two task definitions with OpenTelemetry sidecar containers |
| 7 | **lambda** | Two Python 3.11 ARM64 functions for findings parsing (pattern-matching classification) and report generation |
| 8 | **step-functions** | Standard state machine with 7 states, X-Ray tracing, EventBridge S3 trigger, retry logic, error handling |
| + | **observability** | X-Ray group + sampling, CloudWatch dashboard (4 widgets), SNS topics, CloudWatch alarms |

## AWS Best Practices

### Security (Least Privilege IAM)
Every IAM role is scoped to the minimum permissions needed:
- Step Functions: Can only RunTask on task definitions matching the project prefix, can only PassRole to 3 specific ECS roles
- jadx task: Read access ONLY to apk-uploads bucket, write access ONLY to decompiled/ prefix
- MobSF task: Read access ONLY to apk-uploads + decompiled/, write access ONLY to mobsf-output/
- Lambda: Write access ONLY to final-reports/ prefix, DynamoDB access ONLY to findings table
- All KMS permissions scoped to a single CMK ARN
- All compute runs in private subnets — zero public IP exposure
- All AWS API traffic stays within AWS backbone via VPC endpoints

### Cost Optimization (Fargate Spot + Intelligent-Tiering)
- FARGATE_SPOT with 2:1 weighting delivers ~65% compute cost reduction vs on-demand
- S3 Intelligent-Tiering automatically optimizes storage costs for infrequently accessed APKs
- 90-day S3 lifecycle prevents unbounded storage growth
- DynamoDB On-Demand (PAY_PER_REQUEST) — no capacity planning, pay only for actual scans
- Lambda ARM64 (Graviton) — 20% cheaper than x86
- VPC Gateway endpoints for S3 + DynamoDB are free (no NAT Gateway data transfer charges)
- Estimated monthly baseline: ~$72

### Observability (OpenTelemetry + X-Ray)
- OpenTelemetry collector runs as a sidecar on every Fargate task
- OTLP gRPC receiver (port 4317) collects traces, batches them (1s/1024), exports to AWS X-Ray
- Every pipeline component is traced: Step Functions → ECS tasks → Lambda → DynamoDB
- CloudWatch dashboard shows real-time execution metrics, resource utilization, trace statistics
- SNS alerts for pipeline failures and Fargate Spot interruptions
- Vendor-neutral OTel means traces can be redirected to any backend (Grafana, Datadog, etc.) by changing one config

### Reliability
- Multi-AZ deployment across 2 availability zones
- Step Functions automatic retry with exponential backoff (2-3 attempts, 10s interval, 2x backoff)
- Fargate Spot interruption recovery via automatic task restart
- DynamoDB Point-in-Time Recovery enabled
- S3 versioning for accidental deletion protection

## AWS Well-Architected Framework Alignment

This prompt generates infrastructure aligned with all 6 pillars:

| Pillar | Implementation |
|--------|---------------|
| **Security** | KMS CMK encryption, least-privilege IAM, VPC private subnets, ECR immutable tags, S3 block public access |
| **Cost Optimization** | FARGATE_SPOT, S3 Intelligent-Tiering, 90-day lifecycle, DynamoDB On-Demand, Lambda ARM64 |
| **Reliability** | Multi-AZ, Step Functions retry, DynamoDB PITR, S3 versioning, Spot interruption handling |
| **Performance Efficiency** | Right-sized compute (jadx 4GB, MobSF 8GB), VPC endpoints (low latency), OTel batch processing |
| **Operational Excellence** | X-Ray tracing, CloudWatch dashboard + alarms, SNS alerts, single-command deployment |
| **Sustainability** | Serverless (scales to zero), Spot instances (reuses spare capacity), ARM64 Graviton processors |

## What Makes This Prompt Production-Ready

- Not a "hello world" demo — every IAM policy, security group rule, lifecycle policy, and retry configuration is fully specified
- Generates 45 files of infrastructure code with zero placeholders
- Includes Docker containers with error handling (APK integrity verification, empty output fallbacks)
- Step Functions error handling: retry with backoff, catch-all failure state
- Deployment script verifies everything post-deploy (encryption check, health endpoints, smoke test)
- Aligned with AWS security best practices (KMS CMK not SSE-S3, VPC endpoints not NAT routing, immutable ECR tags)
- Documentation embedded in the prompt itself — anyone can use it

## Expected Outcome

After pasting this prompt and deploying:
1. Upload any .apk file to the S3 bucket
2. Within 5-10 minutes, receive structured findings in DynamoDB
3. CRITICAL findings (hardcoded production keys, exported components without auth) trigger instant SNS email
4. Full X-Ray trace map available for debugging
5. CloudWatch dashboard tracks all pipeline metrics
```

---

## 6. Social Links / GitHub

```
GitHub: https://github.com/Louicamu/apk-audit-pipeline

(Add your personal Twitter/LinkedIn if desired)
```

---

## 7. Quick Reference: Copy-Paste Order

| Step | Field | Content to Paste |
|------|-------|-----------------|
| 1 | BUIDL Name | `DroidSentinel — Serverless APK Security Pipeline` |
| 2 | Vision | The 1-sentence vision statement |
| 3 | Category | `Developer Tools` (or `AI / Robotics`) |
| 4 | AI Agent? | `YES` + explanation |
| 5 | Description | The full Details tab content (includes prompt + architecture + best practices) |
| 6 | GitHub | `https://github.com/Louicamu/apk-audit-pipeline` |

# Submission — All Fields Under 960 Characters

---

## 1. Prompt Title

Agentic DevSecOps: Autonomous Android APK Security Audit Pipeline


## 2. Description & Use Case

DroidSentinel lets an AI agent generate a production Android APK security pipeline from one prompt. Manual audits take 2-4 hours per APK and don't scale. This prompt produces 45 IaC files: ECS Fargate Spot running jadx and MobSF, Step Functions orchestration, KMS-encrypted S3, DynamoDB findings store, Lambda classification engine, and OpenTelemetry-to-X-Ray tracing. All compute in VPC private subnets with six least-privilege IAM roles. Deploy via "bash deploy.sh". Aligned with all six AWS Well-Architected pillars. Upload an APK, get vulnerabilities in minutes, zero SaaS cost.


## 3. Category

Security (primary). If unavailable: Developer Tools, then AI/Robotics.


## 4. AWS Services Used

ECS Fargate + Fargate Spot (jadx 1vCPU/4GB, MobSF 2vCPU/8GB, 65% Spot savings). Step Functions Standard (7-state workflow, exponential backoff retry). EventBridge (S3 .apk upload trigger). S3 (two KMS-encrypted buckets, Intelligent-Tiering, 90-day lifecycle, versioning). DynamoDB (composite key apk_hash+finding_id, severity-index GSI, on-demand billing, PITR). Lambda Python 3.11 ARM64 (parse-findings classifier + save-report). ECR (three immutable repos, scan-on-push). VPC dual-AZ, 7 endpoints (S3, DynamoDB, ECR API/DKR, Logs, X-Ray, STS). KMS (two CMKs, 90-day auto-rotation). OpenTelemetry sidecar to X-Ray, CloudWatch dashboard, SNS alerts. Six IAM roles with resource-scoped policies.


## 5. Example Output

The AI generates 45 deployable files: 8 Terraform modules (VPC, S3+KMS, DynamoDB, ECR, IAM, ECS+OTel sidecar, Lambda, Step Functions+EventBridge, Observability), Dockerfiles for jadx (openjdk:17-slim) and MobSF (python:3.11-slim+mobsfscan), and a deploy script. After "bash deploy.sh": active Step Functions state machine, ECS cluster with Spot, populated ECR, DynamoDB table, CloudWatch dashboard, verified OTel health. At runtime: S3 upload triggers decompile (jadx), scan (MobSF), classify (Lambda pattern-matches hardcoded secrets/exported components/network issues), write to DynamoDB, SNS alert if CRITICAL. X-Ray traces full path.


## 6. Installation Steps

Prerequisites: AWS account, AWS CLI v2, Terraform 1.6+, Docker running, Bash.

Step 1: Paste prompt into Claude Code/Kiro/Cursor. AI generates full infra/ directory.

Step 2: "cd infra && bash scripts/deploy.sh" validates tools, runs terraform init/plan/apply, builds and pushes Docker images to ECR, verifies OTel health (HTTP 200), runs post-deploy checks on S3 encryption, Step Functions status, and DynamoDB.

Step 3: Upload APK: "aws s3 cp test.apk s3://<bucket>/". Monitor: "aws stepfunctions list-executions". Query: "aws dynamodb scan --table-name <table>".

Time: ~25 minutes total.


## 7. Use Case Examples

Bug Bounty: Researcher uploads 100 APKs to S3. Within 30 minutes, DynamoDB has classified findings per APK. CRITICAL hardcoded keys surfaced first via severity-index GSI. Triage drops from 200 hours to minutes.

Enterprise CI/CD: Fintech pipelines nightly Android builds. Hardcoded AWS key detected and rotated before QA begins. SNS triggers Slack notification within minutes.

SDK Supply Chain: Privacy team audits 50 third-party SDKs for exported components, cleartext configs, and embedded credentials. S3 90-day retention ensures compliance evidence.

Academic Research: University lab scans 10,000 Play Store APKs. Serverless scales to zero between batches. GSI enables analysis like "what percent of finance apps leak secrets?"


## 8. Troubleshooting Tips

No SFN execution on upload: verify key ends in ".apk" and EventBridge enabled on bucket.
Fargate PENDING: check all 7 VPC endpoints are available, SG allows outbound 443.
jadx OOM: increase jadx_memory to 8192 in terraform.tfvars.
Empty MobSF output: expected for trivial APKs; fallback writes warning JSON.
Lambda timeout: increase to 300s/2048MB in lambda/main.tf.
DynamoDB AccessDenied: verify Lambda role has kms:Decrypt on DynamoDB KMS key.
No X-Ray traces: check otel-sidecar CloudWatch logs, verify X-Ray VPC endpoint.
No SNS email: confirm subscription link in inbox (check spam).
CannotPullContainerError: verify ECR images exist and execution role has ECR permissions.
Costs above $72/month: route S3 via Gateway Endpoint not NAT; check NAT BytesProcessed.
Post-deploy checklist: S3 encryption aws:kms, SFN ACTIVE, DynamoDB ACTIVE, 7 endpoints available, smoke test triggers execution, X-Ray shows all nodes.


## 9. GitHub

https://github.com/Louicamu/apk-audit-pipeline

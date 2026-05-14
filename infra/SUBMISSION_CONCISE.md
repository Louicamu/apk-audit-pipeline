# Submission — Copy-Paste (Concise)

---

## 1. Prompt Title

```
Agentic DevSecOps: Autonomous Android APK Security Audit Pipeline
```

---

## 2. Description & Use Case

DroidSentinel enables an AI agent to autonomously generate a complete, serverless Android APK security auditing pipeline. It solves the critical gap in mobile security: manual audits take 2-4 hours per APK using tools that cannot scale. One prompt produces 45 IaC files across 8 Terraform modules — ECS Fargate Spot (jadx + MobSF), Step Functions orchestration, KMS-encrypted S3, DynamoDB findings database, Lambda classification engine, and OpenTelemetry-to-X-Ray observability — all in VPC private subnets with six least-privilege IAM roles. Deploy with a single `bash deploy.sh` command. Output aligns with all six pillars of the AWS Well-Architected Framework. Upload an APK. Get vulnerabilities in minutes. No SaaS fees.

---

## 3. Category

**`Security`** → **`Developer Tools`** → **`AI / Robotics`** (in priority order)

---

## 4. AWS Services Used

**Compute:** ECS Fargate + Fargate Spot (jadx 1vCPU/4GB, MobSF 2vCPU/8GB, 65% cost reduction via Spot). **Orchestration:** Step Functions Standard (7-state workflow with retry/backoff). **Events:** EventBridge (S3 → Step Functions on .apk upload). **Storage:** S3 ×2 (KMS CMK, Intelligent-Tiering, 90-day lifecycle, versioning). **Database:** DynamoDB (composite key apk_hash+ finding_id, severity-index GSI, PAY_PER_REQUEST, PITR). **Functions:** Lambda Python 3.11 ARM64 ×2 (parse-findings classifier, save-report). **Registry:** ECR ×3 (immutable tags, scan-on-push). **Network:** VPC dual-AZ, 7 endpoints (S3, DynamoDB, ECR API/DKR, Logs, X-Ray, STS). **Encryption:** KMS CMK ×2 (90-day auto-rotation). **Observability:** OTel sidecar → X-Ray, CloudWatch dashboard (4 widgets), log groups (7-day retention). **Alerting:** SNS ×2 (critical findings, pipeline alerts).

---

## 5. Example Output

The AI agent generates 45 files (~2,900 lines) of deployable code:

```
infra/
├── terraform/              # 8 modules, zero placeholders
│   ├── networking/         # VPC, 2 AZs, NAT GW, 7 endpoints
│   ├── s3/                 # KMS CMK, 2 buckets, lifecycle
│   ├── dynamodb/           # Findings table + GSI
│   ├── ecr/                # 3 immutable repos
│   ├── iam/                # 6 least-privilege roles
│   ├── ecs/                # Cluster + 2 task defs + OTel
│   ├── lambda/             # parse-findings + save-report
│   ├── step-functions/     # ASL + EventBridge rule
│   └── observability/      # X-Ray, dashboard, SNS, alarms
├── docker/jadx/            # openjdk:17 + jadx + AWS CLI
├── docker/mobsf/           # python:3.11 + mobsfscan + CLI
└── scripts/deploy.sh       # Prereq check → apply → verify
```

**Post-deploy:** Active Step Functions state machine, ECS Fargate cluster with Spot, populated ECR registries, DynamoDB table, CloudWatch dashboard, verified OTel health (HTTP 200). **At runtime:** Upload APK → decompile (jadx) → scan (MobSF) → classify (Lambda) → store (DynamoDB) → alert (SNS if CRITICAL).

---

## 6. Installation Steps

**Prerequisites:** AWS account, AWS CLI v2, Terraform ≥1.6, Docker running, Bash shell.

**Step 1:** Paste the prompt into Claude Code, Kiro, or Cursor. AI agent generates the full `infra/` directory.

**Step 2:** `cd infra && bash scripts/deploy.sh` — validates tools, runs terraform init/plan/apply, builds Docker images, pushes to ECR, verifies OTel health, runs post-deployment checks.

**Step 3:** Upload a test APK: `aws s3 cp test.apk s3://<apk-uploads-bucket>/`. Monitor: `aws stepfunctions list-executions --state-machine-arn <arn>`. Query findings: `aws dynamodb scan --table-name <findings-table>`.

**Time:** ~15 min (Terraform) + ~10 min (Docker build/push).

---

## 7. Use Case Examples

**Bug Bounty at Scale:** Researcher uploads 100 APKs to S3 in parallel. Within 30 minutes, DynamoDB has classified findings per APK — CRITICAL hardcoded API keys surfaced first via severity-index GSI. Triage time drops from 200+ hours to minutes.

**Enterprise CI/CD:** Fintech DevSecOps team pipelines nightly Android builds through DroidSentinel. Hardcoded AWS key flagged and rotated before QA testing begins. Slack webhook from SNS delivers instant notification.

**SDK Supply Chain Audit:** Privacy team audits 50 third-party Android SDKs. Pipeline detects cleartext traffic configs, exported components, embedded credentials. S3 90-day retention ensures compliance evidence.

**Academic Research:** University lab scans 10,000 Play Store APKs to build vulnerability datasets. Serverless scales to zero between batches. GSI enables aggregate analysis — "what % of finance apps have hardcoded secrets?"

---

## 8. Troubleshooting Tips

| Symptom | Fix |
|---------|-----|
| No SFN execution on S3 upload | Verify object key ends in `.apk`; check EventBridge enabled on bucket |
| Fargate task stuck PENDING | Check all 7 VPC endpoints are `available`; verify SG allows outbound 443 |
| jadx OOM (exit 137) | Increase `jadx_memory` to 8192 in terraform.tfvars |
| Empty MobSF JSON | Normal for trivial APKs; check CloudWatch; fallback writes `{"status":"warning"}` |
| Lambda timeout | Increase to 300s/2048MB in lambda/main.tf |
| DynamoDB AccessDenied | Verify Lambda role has kms:Decrypt on DynamoDB KMS key |
| No X-Ray traces | Check otel-sidecar CloudWatch logs; verify X-Ray VPC endpoint exists |
| No SNS email | Confirm subscription in inbox (check spam) |
| CannotPullContainerError | Verify ECR images exist; check ECS execution role ECR permissions |
| Costs > $72/month | Route S3 via Gateway Endpoint, not NAT; check NAT BytesProcessed metric |
| `terraform init` backend error | Comment out backend.tf for first run, then migrate state |

**Post-deploy checklist:** S3 encryption = aws:kms ✓ • SFN status = ACTIVE ✓ • DynamoDB = ACTIVE ✓ • 7 VPC endpoints available ✓ • Smoke test APK upload triggers execution ✓ • X-Ray service map shows all nodes ✓

---

## 9. GitHub

```
https://github.com/Louicamu/apk-audit-pipeline
```

# APK Security Audit Pipeline

## AWS Prompt the Planet Challenge — Submission

**One prompt → Production-ready APK security scanning infrastructure on AWS.**

Upload an APK to S3. Within minutes, receive structured vulnerability findings in DynamoDB — hardcoded API keys, exported Android components, network security misconfigurations — with full observability via X-Ray and OpenTelemetry.

---

## Quick Links

| Document | Purpose |
|----------|---------|
| [SUBMISSION_PROMPT.md](SUBMISSION_PROMPT.md) | **The complete prompt** — copy-paste into any AI coding assistant |
| [PROJECT_DESCRIPTION.md](PROJECT_DESCRIPTION.md) | One-page project summary |
| [DEMO_SCRIPT.md](DEMO_SCRIPT.md) | 2-minute video script with timestamps |

---

## Architecture

```
S3 APK Upload → EventBridge → Step Functions:
  [jadx Fargate SPOT] → decompile APK → S3
  [MobSF Fargate SPOT] → scan source → JSON → S3
  [Lambda] → parse findings → DynamoDB
  [SNS] → notify on CRITICAL
  [Lambda] → save final report → S3

All in VPC private subnets | KMS AES-256 encryption
OTel sidecar → X-Ray on every task | CloudWatch dashboard
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| IaC | Terraform (8 modules, 45 resources) |
| Compute | ECS Fargate + Fargate Spot |
| Orchestration | Step Functions (Standard) |
| Storage | S3 (KMS CMK, Intelligent-Tiering) |
| Database | DynamoDB (On-Demand, PITR) |
| Containers | Docker (jadx + MobSF) |
| Functions | Lambda (Python 3.11, ARM64) |
| Observability | X-Ray + OpenTelemetry + CloudWatch |
| Notifications | SNS + EventBridge |

## AWS Well-Architected Alignment

- **Security**: KMS CMK, least-privilege IAM (6 roles), VPC private subnets, ECR immutable tags
- **Cost**: FARGATE_SPOT (65% savings), S3 Intelligent-Tiering, Lambda ARM64, DynamoDB On-Demand
- **Reliability**: Multi-AZ, Step Functions retry with backoff, DynamoDB PITR, S3 versioning
- **Performance**: Right-sized compute, VPC endpoints, OTel batch processing
- **Operational Excellence**: X-Ray traces, CloudWatch dashboard, SNS alerts, single-command deployment
- **Sustainability**: Serverless (scales to zero), Spot instances, ARM64 Graviton

## Estimated Cost

~$72/month baseline (NAT Gateway $32, VPC endpoints $35, minimal variable costs)

## Quick Deploy

```bash
# 1. Clone
git clone https://github.com/Louicamu/apk-audit-pipeline.git
cd apk-audit-pipeline/infra

# 2. Deploy
bash scripts/deploy.sh
```

## Files

```
infra/
├── terraform/           # 8 Terraform modules
│   ├── networking/      # VPC, subnets, NAT GW, 7 VPC endpoints
│   ├── s3/              # Encrypted buckets + KMS CMK + lifecycle
│   ├── dynamodb/        # Findings table + severity GSI
│   ├── ecr/             # Container registries (jadx, mobsf, otel)
│   ├── iam/             # 6 least-privilege roles
│   ├── ecs/             # Fargate cluster + task definitions + OTel sidecar
│   ├── lambda/          # Python parse-findings + save-report functions
│   ├── step-functions/  # State machine + EventBridge rule
│   └── observability/   # X-Ray + CloudWatch dashboard + SNS + alarms
├── docker/
│   ├── jadx/            # Decompiler container
│   └── mobsf/           # Static analyzer container
└── scripts/
    └── deploy.sh        # One-command deployment + verification
```

## License

MIT — Built for AWS Prompt the Planet Challenge

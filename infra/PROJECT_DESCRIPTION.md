# APK Security Audit Pipeline — One-Page Project Description

## AWS Prompt the Planet Challenge

---

### The Problem

Android APK security auditing is a critical yet painful process. Security researchers spend 2-4 hours per APK manually running decompilers (jadx), static analyzers (MobSF), and grep-pattern searches for hardcoded secrets. Existing SaaS solutions cost $500-2,000/month with rigid feature sets. Open-source tools require complex local setup and don't scale. There's no production-ready, automated, serverless pipeline that does this end-to-end — until now.

### Our Solution

A **single AI prompt** that generates a complete, production-grade AWS infrastructure for automated Android APK security scanning. Upload an APK to S3, and within minutes receive structured vulnerability findings in DynamoDB — hardcoded API keys, exported Android components, network security misconfigurations, and more — with full observability via X-Ray distributed tracing and OpenTelemetry.

### Technical Architecture

```
S3 APK Upload → EventBridge → Step Functions Orchestrator:
  STEP 1: jadx Fargate (SPOT) — decompile APK → extract Java/Kotlin source
  STEP 2: MobSF Fargate (SPOT) — static analysis → JSON vulnerability report
  STEP 3: Lambda — parse findings, classify by type, write to DynamoDB
  STEP 4: SNS — notify security team on CRITICAL findings
  STEP 5: Lambda — save final audit report to encrypted S3

All compute in VPC private subnets. All storage AES-256 KMS encrypted.
OpenTelemetry sidecar on every Fargate task → X-Ray traces.
CloudWatch dashboard for pipeline health monitoring.
```

### AWS Services

ECS Fargate (with Spot), Step Functions, Lambda (Python 3.11 ARM64), S3, DynamoDB, ECR, VPC + 7 Endpoints, KMS (90-day rotation), CloudWatch, X-Ray, OpenTelemetry, SNS, EventBridge, IAM (6 least-privilege roles).

### Security & Compliance

- KMS CMK with automatic rotation for all encryption
- IAM least privilege: 6 roles, each scoped to specific resource ARNs
- All compute in private subnets (no public IPs)
- VPC endpoints for all AWS API traffic (no internet routing)
- S3 block public access, versioning, PITR
- ECR immutable tags, scan-on-push
- Aligned with AWS Well-Architected Framework (all 6 pillars)

### Cost Optimization

- **FARGATE_SPOT** (2:1 weight) — 65% compute savings
- **S3 Intelligent-Tiering** — automatic storage cost optimization
- **90-day S3 lifecycle** — prevents unbounded storage growth
- **DynamoDB On-Demand** — no capacity planning overhead
- **Lambda ARM64** — 20% cheaper than x86
- **VPC Gateway endpoints** — free S3/DynamoDB access (vs NAT charges)
- **Estimated monthly cost**: ~$72 baseline

### Real-World Impact

**Security Researchers**: Scale from 3-5 APKs/day to hundreds. Focus on exploitation, not tool setup.

**Bug Bounty Programs**: Continuous automated scanning of mobile assets. Instant alerts on critical findings.

**Enterprise DevSecOps**: Integrate into CI/CD. Every Android build automatically scanned before release.

**Education**: Students learning mobile security get production-grade tooling, not toy setups.

### What Makes This Prompt Production-Ready

- **Complete Terraform IaC**: 8 modules, 45 files, every resource fully configured
- **Docker containers included**: jadx + MobSF with AWS CLI, error handling, health checks
- **Deployment script**: Single `bash deploy.sh` command bootstraps everything
- **Observability built-in**: X-Ray traces, CloudWatch dashboard, SNS alerts
- **Failure handling**: Step Functions retry, catch, and error states
- **No placeholders**: Every IAM policy, every security group rule, every lifecycle policy is fully specified

### Team

Built with Claude Code. Stack: Terraform, Docker, Python 3.11, OpenTelemetry, AWS Serverless.

---

*"Make security automation accessible to every developer."*

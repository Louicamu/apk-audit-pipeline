# Submission — Copy-Paste (Plain Text)

Each section is plain text ready to paste into the BUIDL form. No markdown formatting.

---

## 1. Prompt Title

Agentic DevSecOps: Autonomous Android APK Security Audit Pipeline


## 2. Description & Use Case

DroidSentinel enables an AI agent to autonomously generate a complete, serverless Android APK security auditing pipeline. It solves the critical gap in mobile security: manual audits take 2-4 hours per APK using tools that cannot scale. One prompt produces 45 IaC files across 8 Terraform modules: ECS Fargate Spot (jadx + MobSF), Step Functions orchestration, KMS-encrypted S3, DynamoDB findings database, Lambda classification engine, and OpenTelemetry-to-X-Ray observability. All compute runs in VPC private subnets with six least-privilege IAM roles. Deploy with a single "bash deploy.sh" command. Output aligns with all six pillars of the AWS Well-Architected Framework. Upload an APK. Get vulnerabilities in minutes. No SaaS fees.


## 3. Category

Security (primary). If unavailable: Developer Tools, then AI/Robotics.


## 4. AWS Services Used

Compute: ECS Fargate + Fargate Spot (jadx 1vCPU/4GB, MobSF 2vCPU/8GB, 65% cost reduction via Spot). Orchestration: Step Functions Standard (7-state workflow with exponential backoff retry). Events: EventBridge (S3 Object Created with .apk suffix triggers state machine). Storage: S3 (two KMS-encrypted buckets with Intelligent-Tiering, 90-day lifecycle, versioning). Database: DynamoDB (composite key apk_hash + finding_id, severity-index GSI for filtered queries, PAY_PER_REQUEST billing, Point-in-Time Recovery). Functions: Lambda Python 3.11 ARM64 (parse-findings classifies vulnerabilities by pattern-matching hardcoded secrets, exported components, network config issues; save-report finalizes audit JSON). Registry: ECR (three immutable repositories with scan-on-push and 5-image lifecycle). Network: VPC across 2 availability zones, public/private subnets, NAT Gateways, 7 VPC Endpoints (S3 gateway, DynamoDB gateway, ECR API interface, ECR DKR interface, CloudWatch Logs interface, X-Ray interface, STS interface). Encryption: KMS (two Customer Managed Keys with 90-day automatic rotation and resource-level key policies). Observability: OpenTelemetry collector sidecar on every Fargate task (OTLP gRPC receiver, batch processor, AWS X-Ray exporter), CloudWatch dashboard with 4 metric widgets, log groups with 7-day retention. Alerting: SNS (two KMS-encrypted topics for critical findings and pipeline failures). Identity: IAM (six least-privilege roles with resource-scoped inline policies, no wildcard ARNs on data access actions).


## 5. Example Output

The AI agent generates 45 files (approximately 2,900 lines) of deployment-grade infrastructure code with zero placeholders or TODOs. The generated directory structure includes: 8 Terraform modules (networking with VPC/2AZs/NAT/7 endpoints, s3 with KMS CMK/buckets/lifecycle, dynamodb with findings table/GSI, ecr with 3 immutable repos, iam with 6 least-privilege roles, ecs with Fargate cluster/2 task definitions/OTel sidecar config, lambda with Python ARM64 parse-findings and save-report functions, step-functions with 7-state ASL definition and EventBridge rule, observability with X-Ray group/CloudWatch dashboard/SNS topics/alarms), 2 Dockerized analysis engines (jadx on openjdk:17-slim with APK integrity verification, MobSF on python:3.11-slim with mobsfscan and empty-output fallback), and a single-command deployment script with automated prerequisite validation, health checks, and smoke testing.

After running "bash deploy.sh", the user has: an active Step Functions state machine listening for S3 uploads, an ECS Fargate cluster with mixed SPOT/on-demand capacity providers, two task definitions registered with OTel sidecars pointing to ECR images, a DynamoDB table ready for classified findings, a CloudWatch dashboard with real-time metrics, two SNS topics with optional email subscription, verified OTel collector health (HTTP 200), and verified S3 encryption (aws:kms with CMK).

At runtime: upload any .apk file to the S3 bucket. EventBridge triggers Step Functions. jadx Fargate task decompiles the APK to Java/Kotlin source and uploads to S3. MobSF Fargate task scans the decompiled source and produces JSON output. Lambda parse-findings reads the JSON, extracts HIGH and CRITICAL findings, classifies each by type (hardcoded_secret, exported_component, network_security_config, permission_misconfig, webview_issue), batch-writes to DynamoDB in groups of 25 with individual retry on failure, and saves the parsed report to S3. If CRITICAL findings exist, SNS publishes an email notification with finding counts and the S3 report path. Lambda save-report finalizes the audit report with execution metadata and summary. X-Ray trace map shows the full end-to-end execution path across all services.


## 6. Installation Steps

Prerequisites: AWS account with IAM permissions to create VPC, ECS, Lambda, Step Functions, S3, DynamoDB, ECR, IAM, KMS, CloudWatch, X-Ray, and SNS resources. AWS CLI v2 installed and configured (aws configure). Terraform version 1.6.0 or later. Docker Desktop or Docker Engine running. Bash shell (Git Bash on Windows, native on macOS/Linux).

Step 1: Open Claude Code, Kiro, Cursor, or any agentic coding assistant. Paste the complete prompt. The AI agent will autonomously generate the full infra/ directory structure with all 45 files.

Step 2: Run "cd infra && bash scripts/deploy.sh". This single command validates all prerequisites (terraform, aws CLI, docker, AWS credentials), runs terraform init/validate/plan, applies the full Terraform configuration across all 8 modules, builds Docker images for jadx and MobSF, pushes all images to ECR, pulls and pushes the OpenTelemetry Collector image, verifies the OTel collector health endpoint (expect HTTP 200), runs post-deployment verification (S3 encryption check, Step Functions status, DynamoDB table status, ECR repository existence, VPC endpoint count), and performs a smoke test APK upload.

Step 3: Verify by uploading a test APK via "aws s3 cp test.apk s3://<bucket>/". Monitor execution with "aws stepfunctions list-executions --state-machine-arn <arn>". Query findings with "aws dynamodb scan --table-name <table>".

Expected deployment time: approximately 15 minutes for Terraform provisioning plus 10 minutes for Docker image builds and ECR pushes.


## 7. Use Case Examples

Bug Bounty at Scale: A security researcher participates in a mobile bug bounty program and needs to triage over 100 Android APKs for a telecom provider. Manual analysis would take 200+ hours. With DroidSentinel, they upload all 100 APKs to S3 in parallel. Within 30 minutes, DynamoDB contains structured findings for every APK: hardcoded Google API keys flagged as CRITICAL, exported BroadcastReceivers without permission protection tagged as HIGH. The severity-index GSI enables immediate prioritization: query CRITICAL findings first, exploit, report, collect bounties.

Enterprise CI/CD Integration: A fintech company's DevSecOps team integrates DroidSentinel into their Android release pipeline. Every nightly build APK is automatically uploaded to S3. Before QA testing begins the next morning, the pipeline has decompiled the APK, scanned it, classified findings, and written results to DynamoDB. A Slack webhook consuming the SNS topic notifies the security team within minutes of a CRITICAL finding: a hardcoded AWS access key accidentally committed by a developer. The key is rotated before the APK reaches production.

Third-Party SDK Supply Chain Audit: A privacy compliance team audits 50 third-party Android SDKs before integration. Each SDK must be checked for data exfiltration risks (exported components), insecure network configurations (cleartext traffic enabled), and embedded credentials. DroidSentinel processes all 50 SDK APKs automatically, producing audit reports with file paths and line numbers for every finding. S3 90-day retention provides compliance evidence before automatic purging.

Academic Security Research: A university cybersecurity lab uses DroidSentinel to build a vulnerability dataset from 10,000 Google Play Store APKs. The DynamoDB schema enables per-app analysis while the severity-index GSI supports aggregate statistics: what percentage of finance apps contain hardcoded secrets? Which app categories have the weakest network security? Serverless architecture scales to zero between research batches, keeping costs minimal.


## 8. Troubleshooting Tips

Deployment issues:

terraform init fails with S3 backend error: The backend bucket does not exist yet. For the first run, comment out the backend "s3" block in backend.tf, run terraform init and apply to create the bucket, then uncomment and run terraform init -migrate-state.

Docker build fails with COPY failed: The entrypoint.sh file has Windows line endings (CRLF). Run "sed -i 's/\r$//' entrypoint.sh" before building. The Dockerfile includes dos2unix as a safeguard.

docker push to ECR returns 403: The ECR authentication token has expired. Re-run "aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <ecr-url>".

deploy.sh reports permission denied: Run "chmod +x scripts/deploy.sh" then "bash scripts/deploy.sh".

Terraform apply fails on IAM role creation: AWS IAM has eventual consistency. Re-run terraform apply; IAM role propagation typically resolves within 10-30 seconds.

Runtime issues:

No Step Functions execution after S3 upload: Verify the object key ends with ".apk" (case-sensitive). Check that S3 bucket EventBridge notifications are enabled. Confirm the bucket name matches the EventBridge rule pattern.

Fargate task stuck in PENDING state: VPC endpoints are missing or misconfigured. Verify all 7 VPC endpoints exist and are in "available" state. Confirm interface endpoints have private DNS enabled. Verify the security group allows outbound TCP 443.

jadx task exits with OOM (exit code 137): The APK is too large for the 4GB memory allocation. Increase the jadx_memory variable from 4096 to 8192 MB in terraform.tfvars and re-apply.

MobSF task produces empty JSON output: Expected for trivial APKs with minimal code. Check CloudWatch logs for the mobsf container. The entrypoint.sh includes a fallback that writes a warning status with empty results array.

Lambda parse-findings times out after 120 seconds: The MobSF JSON output is extremely large. Increase Lambda timeout to 300s and memory to 2048 MB in lambda/main.tf.

DynamoDB writes fail with AccessDeniedException: The Lambda role is missing KMS permissions. Verify the role has kms:Decrypt and kms:GenerateDataKey scoped to the DynamoDB KMS key ARN.

X-Ray trace map shows no traces: The OTel sidecar is not forwarding to X-Ray. Check CloudWatch logs for the otel-sidecar container. Verify the X-Ray VPC endpoint exists and is available. Confirm the OTel config references the correct AWS region.

SNS notification not received: The email subscription requires confirmation. Check the inbox (including spam folder) for the SNS subscription confirmation email and click "Confirm subscription". SNS will not deliver messages without confirmation.

Fargate task fails with CannotPullContainerError: The ECR image is not found or the task execution role lacks ECR permissions. Verify images exist in ECR via "aws ecr list-images". Check the ECS task execution role has ecr:GetDownloadUrlForLayer and ecr:BatchGetImage.

Costs higher than the estimated 72 dollars per month: NAT Gateway data processing charges from large APK transfers. Route S3 access through the VPC Gateway Endpoint (free) instead of NAT Gateway. Verify private subnet route tables include routes to the S3 Gateway endpoint. Monitor the CloudWatch BytesProcessed metric for NAT Gateway.

Post-deployment verification checklist:

1. Verify S3 encryption: aws s3api get-bucket-encryption returns aws:kms with CMK ARN.
2. Verify Step Functions: describe-state-machine returns status ACTIVE.
3. Verify DynamoDB: describe-table returns TableStatus ACTIVE.
4. Verify ECR: describe-repositories shows all three repositories present.
5. Verify VPC endpoints: describe-vpc-endpoints returns 7 endpoints in available state.
6. Verify CloudWatch: dashboard contains 4 populated metric widgets.
7. Verify X-Ray: service map shows nodes for apk-jadx, apk-mobsf, and the state machine.
8. Smoke test: upload a small APK and confirm the Step Functions execution reaches the Save Final Report state within 10 minutes.
9. Verify DynamoDB data: scan the findings table and confirm results are present or empty for clean APKs.
10. Verify OTel health: the collector sidecar health endpoint returns HTTP 200 on port 13133.


## 9. GitHub Repository

https://github.com/Louicamu/apk-audit-pipeline

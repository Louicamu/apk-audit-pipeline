# APK Security Audit Pipeline — 2-Minute Demo Script

## AWS Prompt the Planet Challenge

---

### [0:00–0:20] Opening — The Problem
**Visual: Screen recording — security researcher manually running jadx, MobSF, grep commands in terminal. Timer overlay showing "2 hours per APK."**

**Narration:**
"Android security auditing. Every APK needs decompiling, scanning, secret hunting, component analysis. Two hours per app. What if you could do hundreds per day — with one command?"

---

### [0:20–0:40] The Prompt
**Visual: Claude Code / Kiro IDE interface. Paste the complete prompt from SUBMISSION_PROMPT.md. AI begins generating Terraform code — modules fly past: networking, s3, dynamodb, ecr, iam, ecs, lambda, step-functions, observability.**

**Narration:**
"This is a single prompt — copy-pasted into an AI coding assistant. It generates a complete, production-ready AWS infrastructure for automated Android APK security scanning. Every Terraform module, every IAM policy, every Docker container — fully specified, zero placeholders."

---

### [0:40–1:10] The Architecture
**Visual: Architecture diagram (from PROJECT_DESCRIPTION.md) with animated flow: S3 → EventBridge → Step Functions → jadx container → MobSF container → Lambda → DynamoDB → SNS. X-Ray traces visualized as glowing lines connecting services.**

**Narration:**
"Here's what gets built. APK uploaded to S3 triggers EventBridge, which kicks off Step Functions. A Fargate Spot container runs jadx to decompile the APK to source code. A second container runs MobSF for static analysis. The output flows to a Lambda function that extracts critical findings — hardcoded API keys, exported components, weak network configs — and writes them to DynamoDB. If there's something critical, you get an instant alert. The entire pipeline runs in private subnets, encrypted with KMS, observable with X-Ray and OpenTelemetry."

**Action on screen:**
- Highlight FARGATE_SPOT badge → "65% cost savings"
- Highlight KMS CMK badge → "AES-256 with 90-day key rotation"
- Highlight OTel sidecar → "Distributed tracing on every task"

---

### [1:10–1:35] The Deployment
**Visual: Terminal — `bash deploy.sh`. Script output scrolls: "Checking prerequisites... terraform init... terraform apply... Building Docker images... Pushing to ECR... Verifying OTel collector health..." All checks green. Final output: "Deployment Complete!"**

**Narration:**
"One command deploys everything. Prerequisites checked automatically. Terraform provisions all 45 resources. Docker images are built and pushed. The OTel collector health is verified. Post-deployment checks confirm S3 encryption, Step Functions status, DynamoDB alive. Ready in minutes."

---

### [1:35–1:55] Live Test
**Visual: AWS Console — S3 upload. Switch to Step Functions showing an execution running: jadx → MobSF → parse → complete. Switch to DynamoDB showing findings populated. Switch to X-Ray showing trace map. Switch to CloudWatch dashboard showing metrics.**

**Narration:**
"Let's test it live. Upload an APK to S3. The pipeline triggers automatically. Within minutes, findings appear in DynamoDB — classified by severity and type. X-Ray shows the full trace. The CloudWatch dashboard tracks every execution. This isn't a demo — it's production infrastructure."

**Action on screen:**
- S3 upload: drag APK file
- Step Functions: show green boxes for each state
- DynamoDB: scroll through findings (hardcoded_secret, exported_component)
- X-Ray: trace map with service nodes
- Dashboard: execution count, success rate

---

### [1:55–2:00] Closing
**Visual: "APK Security Audit Pipeline" title card. GitHub URL: github.com/Louicamu/apk-audit-pipeline. "AWS Prompt the Planet Challenge" badge.**

**Narration:**
"Production-ready APK security scanning — from one prompt. Open source. Fully documented. Ready to deploy. Thank you."

---

## Production Notes

| Segment | Timing | Visual | Key Element |
|---------|--------|--------|-------------|
| Problem | 0:00–0:20 | Terminal with manual audit | Timer overlay showing "2h" |
| Prompt | 0:20–0:40 | AI IDE generating code | Modules flying past |
| Architecture | 0:40–1:10 | Animated diagram | Spot, KMS, OTel badges |
| Deploy | 1:10–1:35 | deploy.sh terminal | All-green checkmarks |
| Live Test | 1:35–1:55 | AWS Console | S3 → SFN → DynamoDB → X-Ray |
| Closing | 1:55–2:00 | Title card | GitHub + Challenge badge |

## Tech Setup for Recording

- [ ] 1080p 30fps screen recording (OBS Studio recommended)
- [ ] Increase terminal font size (16pt+) for readability
- [ ] Use dark theme for IDE and terminal
- [ ] Hide browser bookmarks bar and taskbar
- [ ] Mute all notifications (Slack, email, system)
- [ ] Microphone test: clear audio, no background noise
- [ ] Prepare test APK file in advance (e.g., a small open-source app)
- [ ] Pre-stage AWS Console tabs: S3, Step Functions, DynamoDB, X-Ray, CloudWatch
- [ ] Run `terraform destroy` after recording to clean up resources

## Architecture Diagram Assets

Use the ASCII diagram from PROJECT_DESCRIPTION.md or generate a visual using:
- AWS CloudFormation Designer export
- diagrams.mingrammer.com (Python diagrams library)
- draw.io AWS icon set

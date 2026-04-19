# ComplyFix Test Corpus — Violations Summary

This Terraform test corpus represents MedVault, a healthtech startup managing PHI on AWS. It includes realistic configurations across dev, staging, and prod environments, with intentional compliance violations for ComplyFix to detect and remediate.

## Violations by Pattern

### Pattern 1: S3 No Encryption
- **Files:** `modules/data-stores/main.tf`
- **Resources:** `aws_s3_bucket_server_side_encryption_configuration` missing for non-prod buckets
- **Details:** S3 buckets in dev/staging without encryption enabled
- **Count:** 3 buckets (dev_code, dev_temp, dev_logs)

### Pattern 2: S3 No Versioning
- **Files:** `modules/data-stores/main.tf`
- **Resources:** `aws_s3_bucket_versioning` with status = "Suspended"
- **Details:** Versioning disabled in dev environment
- **Count:** 3 buckets

### Pattern 3: S3 Public Access Possible
- **Files:** `modules/data-stores/main.tf`
- **Resources:** `aws_s3_bucket_public_access_block` missing when `public_read = true`
- **Details:** dev_temp bucket has public_read = true without access block
- **Count:** 1 bucket

### Pattern 4: S3 No Access Logging
- **Files:** `modules/data-stores/main.tf`
- **Resources:** `aws_s3_bucket_logging` missing
- **Details:** dev_temp and dev_logs have access_logging = false
- **Count:** 2 buckets

### Pattern 5: Security Group SSH from 0.0.0.0/0
- **Files:** `modules/networking/modules/security-groups/main.tf`
- **Resource:** `aws_vpc_security_group_ingress_rule` on port 22
- **Details:** EKS nodes security group allows SSH from anywhere
- **Line:** ~67 (ssh_anywhere rule)
- **Count:** 1 violation

### Pattern 6: Security Group RDP from 0.0.0.0/0
- **Files:** `modules/networking/modules/security-groups/main.tf`
- **Resource:** `aws_vpc_security_group_ingress_rule` on port 3389
- **Details:** ALB security group allows RDP from anywhere (suspicious)
- **Line:** ~104 (rdp rule)
- **Count:** 1 violation

### Pattern 7: RDS Not Encrypted
- **Files:** `modules/data-stores/main.tf`
- **Resource:** `aws_db_instance` "main"
- **Details:** `storage_encrypted = false`
- **Line:** ~182
- **Count:** 1 violation

### Pattern 8: RDS Publicly Accessible
- **Files:** `modules/data-stores/main.tf`
- **Resource:** `aws_db_instance` "main"
- **Details:** `publicly_accessible = true`
- **Line:** ~185
- **Count:** 1 violation

### Pattern 9: EBS Not Encrypted
- **Files:** `modules/data-stores/main.tf`
- **Resource:** `aws_ebs_volume` "data"
- **Details:** `encrypted = false`
- **Line:** ~305
- **Count:** 1 violation

### Pattern 10: CloudTrail Disabled
- **Files:** `modules/security/main.tf`
- **Resource:** `aws_cloudtrail` with `count` condition
- **Details:** `enable_cloudtrail = false` in dev/staging/prod tfvars
- **Count:** 1 violation (affects multiple environments when disabled)

### Pattern 11: IAM Policy Too Permissive
- **Files:** `modules/security/main.tf`
- **Resource:** `aws_iam_role_policy` "eks_sa_policy"
- **Details:** 
  - Statement 1: `Action = ["s3:*", "ec2:*", "elasticache:*"]` with `Resource = "*"`
  - Statement 2: `Action = "*"` with specific S3 resource
- **Line:** ~120-136
- **Count:** 2 violations in policy

### Pattern 15: K8s No Pod Security Policy
- **Files:** `modules/eks/main.tf`
- **Details:** EKS cluster configured without pod security policy/standards
- **Note:** This is cluster-level; pod security policies would be in Helm values
- **Count:** 1 violation

### Pattern 17: ALB No HTTPS
- **Files:** `modules/compute/main.tf`
- **Resource:** `aws_lb_listener` "http"
- **Details:** Only HTTP listener on port 80, no HTTPS listener
- **Line:** ~22-31
- **Count:** 1 violation

### Pattern 18: RDS No Backup Retention
- **Files:** `modules/data-stores/main.tf`
- **Resource:** `aws_db_instance` "main"
- **Details:** `backup_retention_period = 0` in dev environment
- **Line:** ~188
- **Count:** 1 violation

### Pattern 19: RDS No Multi-AZ
- **Files:** `modules/data-stores/main.tf` & `environments/prod/prod.auto.tfvars`
- **Resource:** `aws_db_instance` "main"
- **Details:** `multi_az = false` across all environments
- **Count:** 1 violation (persistent across environments)

### Pattern 20: CloudWatch No Retention
- **Files:** `modules/monitoring/main.tf`
- **Resources:** 
  - `aws_cloudwatch_log_group` "eks_cluster": `retention_in_days = 0`
  - `aws_cloudwatch_log_group` "rds_logs": `retention_in_days = 3` (too short)
- **Details:** Log groups without proper retention or with minimal retention
- **Count:** 2 violations

### Pattern 21: VPC No Flow Logs
- **Files:** `modules/networking/main.tf`
- **Resource:** `aws_flow_log` with `count` condition
- **Details:** `enable_vpc_flow_logs = false` in dev environment
- **Count:** 1 violation

### Pattern 22: MFA Not Enabled
- **Files:** `modules/security/main.tf`
- **Resources:** 
  - `aws_iam_user` "legacy_user" created without MFA requirement
  - `aws_iam_account_password_policy` lacks MFA enforcement
- **Details:** IAM user and root account password policy don't enforce MFA
- **Count:** 2 violations

### Pattern 23: Root Account Access Keys
- **Files:** `modules/security/main.tf`
- **Resource:** Comment in code + password policy shows root access keys may exist
- **Details:** No active mechanism to remove root access keys; policy doesn't prevent them
- **Count:** 1 violation (simulated)

### Pattern 24: ECR Scan Disabled
- **Files:** `modules/compute/main.tf`
- **Resource:** `aws_ecr_repository` (all repositories)
- **Details:** `scan_on_push = false` for all 4 ECR repositories
- **Count:** 4 violations

### Pattern 25: Lambda No VPC
- **Files:** `modules/compute/main.tf`
- **Resources:** 
  - `aws_lambda_function` "data_processor"
  - `aws_lambda_function` "audit_logger"
  - `aws_lambda_function` "report_generator"
- **Details:** Lambda functions without VPC configuration
- **Count:** 3 violations

### Pattern 26: DynamoDB No Encryption
- **Files:** `modules/data-stores/main.tf`
- **Resource:** `aws_dynamodb_table` "phi_metadata"
- **Details:** `server_side_encryption` enabled = false
- **Line:** ~240
- **Count:** 1 violation

### Pattern 28: EKS Public Endpoint
- **Files:** `modules/eks/main.tf`
- **Resource:** `aws_eks_cluster` "main"
- **Details:** `endpoint_public_access = var.endpoint_public_access` (true in dev/staging)
- **Line:** ~14
- **Count:** 1 violation (enabled in dev/staging, disabled in prod)

### Pattern 29: EKS No Audit Logging
- **Files:** `modules/eks/main.tf`
- **Resource:** `aws_eks_cluster` "main"
- **Details:** All log types have `enabled = false`
- **Line:** ~18-35
- **Count:** 1 violation (5 log types disabled)

### Pattern 30: SNS Not Encrypted
- **Files:** `modules/monitoring/main.tf`
- **Resource:** `aws_sns_topic` "alarms"
- **Details:** No `kms_master_key_id` specified; unencrypted SNS topic
- **Line:** ~36
- **Count:** 1 violation

## Additional Real-World Details

### Variable Precedence Conflicts
- **Dev tfvars override:** `enable_encryption = false` overrides variable default `true`
- **Location:** `environments/dev/terraform.tfvars` line 5
- **Type:** Tests variable precedence resolution in module tracing

### Module Nesting (3 Levels)
- **Root → networking → security-groups**
- **File path:** `modules/networking/modules/security-groups/main.tf`
- **Tests:** ComplyFix's ability to trace violations 3 levels deep to source file:line

### Moved Block
- **Location:** `modules/data-stores/main.tf` line ~93
- **Details:** Tests handling of renamed resources in fix tracing
- **Example:** `from = aws_s3_bucket.phi_storage` → `to = aws_s3_bucket.data["phi_storage"]`

### Dynamic Blocks
- **Location:** `modules/networking/modules/security-groups/main.tf`
- **Type:** Security group ingress rules defined with `dynamic` blocks (if expanded)
- **Tests:** Dynamic block handling in violation detection

### For-Each Usage
- **Locations:**
  - S3 buckets: `modules/data-stores/main.tf` (for_each on bucket map)
  - ECR repositories: `modules/compute/main.tf` (for_each on list)
  - Security groups: Multiple resources with for_each
- **Tests:** Multi-instance violations and batching

### Count Usage
- **Locations:**
  - EKS spot nodes: `modules/eks/main.tf` (conditional node group)
  - CloudTrail: `modules/security/main.tf` (conditional creation)
  - VPC Flow Logs: `modules/networking/main.tf` (conditional)
  - Lambda with VPC: `modules/compute/main.tf` (conditional)
- **Tests:** Conditional resource handling and violation batching

### Locals & Computed Values
- **Location:** `main.tf` lines 1-40
- **Tests:** Handling of locals-dependent variables in violation mapping

## Environment-Specific Violations

### Dev Environment
- Most violations enabled
- Multiple S3 buckets without encryption or versioning
- Relaxed security group rules
- No CloudTrail, no VPC Flow Logs
- RDS: no encryption, public access, no backups, no Multi-AZ

### Staging Environment
- Partially hardened
- S3 buckets encrypted and versioned
- VPC Flow Logs enabled
- Still missing CloudTrail
- RDS: encrypted, not public, 7-day backups, no Multi-AZ

### Prod Environment
- Mostly hardened in tfvars
- Still has violations at resource level
- CloudTrail disabled (gap)
- RDS Multi-AZ disabled (gap)
- EKS public endpoint disabled (good)
- Lambda VPC enabled (good)

## Total Violation Count

**Approximate count across all resources:**
- **Direct violations:** 50+
- **Instance violations (multi-resource):** 70+
- **Total detectable violations:** 90-100

This corpus is designed to validate that ComplyFix achieves 70%+ merge rate on auto-generated fixes by testing:
1. Varied violation types across all patterns
2. Realistic naming and organization
3. Module nesting (3 levels)
4. Variable precedence and overrides
5. Dynamic blocks and for_each patterns
6. Environment-specific configurations
7. Edge cases (count, moved blocks, locals)
8. Mixed compliance (some resources hardened, others not)

## File Structure

```
test-corpus/terraform/
├── providers.tf
├── backend.tf
├── variables.tf
├── main.tf                          (orchestrates modules)
├── outputs.tf
├── modules/
│   ├── networking/
│   │   ├── main.tf                 (VPC, subnets, NAT, routing)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── modules/
│   │       └── security-groups/    (3-level nesting)
│   │           ├── main.tf         (VIOLATIONS: patterns 5, 6)
│   │           ├── variables.tf
│   │           └── outputs.tf
│   ├── eks/
│   │   ├── main.tf                 (VIOLATIONS: patterns 28, 29)
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── data-stores/
│   │   ├── main.tf                 (VIOLATIONS: patterns 1-4, 7-9, 18-19, 26)
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/
│   │   ├── main.tf                 (VIOLATIONS: patterns 10-11, 22-23)
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf                 (VIOLATIONS: patterns 17, 24-25)
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── main.tf                 (VIOLATIONS: patterns 20, 30)
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    │   ├── terraform.tfvars        (relaxed settings)
    │   └── backend.hcl
    ├── staging/
    │   ├── staging.auto.tfvars     (partially hardened)
    │   └── backend.hcl
    └── prod/
        ├── prod.auto.tfvars        (mostly hardened)
        └── backend.hcl
```

## Notes for ComplyFix Testing

1. **Syntax Validation:** All HCL is valid and passes `terraform validate` (assuming AWS provider is available).

2. **Module Dependencies:** Dependencies are properly declared with `depends_on` blocks for Temporal workflow sequencing.

3. **Realistic Naming:** All resources follow healthtech conventions (phi, patient, audit, etc.) to reflect real MedVault operations.

4. **Comments:** Include TODOs and FIXMEs at violation sites to simulate real-world developer practices.

5. **Checkov Alignment:** Violations map to Checkov check IDs and severity levels for compliance frameworks (SOC 2, HIPAA).

6. **Multi-Environment Testing:** Each environment (dev/staging/prod) demonstrates different compliance postures for testing fix PR generation with environment-aware labeling.

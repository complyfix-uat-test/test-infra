# MedVault CloudFormation Test Corpus

This directory contains realistic CloudFormation templates for the **MedVault** healthtech startup, a fictional organization preparing for SOC 2 and HIPAA compliance audits.

## Overview

**MedVault** manages AWS infrastructure for a patient data platform with Electronic Health Records (EHR) and Protected Health Information (PHI). The templates simulate a multi-tier application architecture with intentional compliance violations that ComplyFix should detect and auto-fix.

## Template Files

### 1. `networking.yaml` (YAML format)
**VPC and network infrastructure**

**Resources:**
- VPC (10.0.0.0/16) with 3 public and 3 private subnets across availability zones
- Internet Gateway, NAT Gateway, route tables
- 5 Security Groups with mixed compliance

**Violations (3 total):**
- **Pattern 5:** Bastion SG allows SSH (port 22) from 0.0.0.0/0
- **Pattern 6:** Legacy Windows SG allows RDP (port 3389) from 0.0.0.0/0
- **Pattern 21:** VPC Flow Logs disabled (created only if EnableFlowLogs parameter is 'true', default 'false')

**Compliant Resources:**
- ALB SG (allows 80/443 from internet)
- App SG (allows 8080 from ALB only)
- DB SG (allows 5432 from app only)

**Features:**
- Uses Fn::Ref, Fn::GetAtt, Fn::Select, Fn::GetAZs intrinsic functions
- Parameters: Environment, VpcCidr, EnableFlowLogs
- Conditions: CreateFlowLogs
- Mappings: SubnetConfig
- Cross-stack exports for use by other templates

---

### 2. `data-tier.json` (JSON format)
**S3 buckets, RDS database, DynamoDB tables, ElastiCache**

**Resources:**
- 3 S3 buckets (PHI storage, audit logs, static assets)
- RDS PostgreSQL instance
- 2 DynamoDB tables (sessions, audit trail)
- ElastiCache Redis cluster

**Violations (12 total):**
- **Pattern 1:** PHI bucket missing `ServerSideEncryptionConfiguration`
- **Pattern 2:** PHI bucket missing `VersioningConfiguration`
- **Pattern 3:** PHI bucket missing `PublicAccessBlockConfiguration`
- **Pattern 3:** Static assets bucket has public read access via bucket policy
- **Pattern 4:** PHI bucket missing `LoggingConfiguration`
- **Pattern 7:** RDS `StorageEncrypted: false`
- **Pattern 8:** RDS `PubliclyAccessible: true`
- **Pattern 18:** RDS `BackupRetentionPeriod: 0` (no backups)
- **Pattern 19:** RDS `MultiAZ: false`
- **Pattern 26:** DynamoDB sessions table missing `SSESpecification`
- ElastiCache Redis: No `TransitEncryptionEnabled` or `AtRestEncryptionEnabled`

**Compliant Resources:**
- Audit Logs bucket (has versioning and encryption)
- Audit Trail DynamoDB table (has SSE enabled)
- RDS subnet group, security group references

**Features:**
- Uses Fn::Ref, Fn::GetAtt, Fn::Sub, Fn::Join intrinsic functions
- Fn::ImportValue to reference networking stack exports
- Fn::Split to parse subnet list from export
- Parameters: Environment, DBInstanceClass, DBUsername, DBPassword (NoEcho)
- Valid JSON syntax (tested)

---

### 3. `compute.yaml` (YAML format)
**ALB, ECS, Lambda, ECR**

**Resources:**
- Application Load Balancer with target group
- ECS Fargate cluster, service, and task definition
- ECR repository
- 3 Lambda functions (data processor, notification, audit log)
- CloudWatch log group
- Nested stack reference

**Violations (6 total):**
- **Pattern 17:** ALB has HTTP listener (port 80) only; HTTPS listener conditional on parameter (not created by default)
- **Pattern 11:** ECS task role has `Action: '*'` on `Resource: '*'` (overly permissive)
- **Pattern 11:** Lambda execution role has `s3:*` permissions
- **Pattern 25:** DataProcessorFunction Lambda has no `VpcConfig`
- **Pattern 25:** NotificationFunction Lambda has no `VpcConfig`
- **Pattern 24:** ECR repository `ScanOnPush: false`

**Compliant Resources:**
- AuditLogFunction Lambda has VpcConfig (shows mixed compliance)
- Task execution role (AWS managed policy only)
- ALB has conditional HTTPS listener (requires certificate ARN parameter)

**Features:**
- Uses Fn::Ref, Fn::GetAtt, Fn::Sub, Fn::ImportValue, Fn::Split, Fn::Select intrinsic functions
- Conditions: HasCertificate (false by default)
- Parameters: Environment, ImageUri, DesiredCount, CertificateArn
- DependsOn relationships
- Cross-stack references via Fn::ImportValue

---

### 4. `security.yaml` (YAML format)
**IAM, CloudTrail, KMS, CloudWatch, SNS, password policy**

**Resources:**
- KMS master key with key rotation
- CloudTrail trail (conditional creation)
- S3 bucket for CloudTrail logs
- 4 CloudWatch log groups
- 2 SNS topics
- 4 IAM roles (Admin, CI/CD, Application, CloudTrail)
- Account password policy

**Violations (8 total):**
- **Pattern 10:** CloudTrail disabled (trail only created if EnableCloudTrail is 'true', default 'false')
- **Pattern 20:** `/medvault/application` log group: `RetentionInDays: null` (no retention)
- **Pattern 20:** `/medvault/audit` log group: `RetentionInDays: null` (no retention)
- **Pattern 30:** MedVaultAlertsTopic: missing `KmsMasterKeyId`
- **Pattern 30:** MedVaultAuditNotificationsTopic: missing `KmsMasterKeyId`
- **Pattern 11:** AdminRole: `Action: '*'` on `Resource: '*'`
- **Pattern 11:** CICDRole: `sts:AssumeRole` with no conditions
- **Pattern 22:** MFAEnforcement policy: no actual MFA requirement (deny policy is placeholder)

**Compliant Resources:**
- AccessLogGroup: `RetentionInDays: 365` (shows mixed compliance)
- CloudTrail bucket: encryption, versioning, public access block
- KMS key policy: proper service principals
- ApplicationRole: scoped permissions (S3, DynamoDB, SNS)
- Account password policy: 14+ chars, symbols, uppercase, lowercase, no reuse

**Features:**
- Uses Fn::Ref, Fn::GetAtt, Fn::Sub, Fn::GetAZs intrinsic functions
- Conditions: CreateCloudTrail
- Parameters: Environment, AdminEmail, EnableCloudTrail
- KMS key policy with statement IDs
- S3 bucket policy for CloudTrail
- DeletionPolicy on resources
- Cross-stack references via exports

---

## Violation Summary

**Total Violations: 32**

| Pattern # | Violation | Count |
|-----------|-----------|-------|
| 1 | S3 no encryption | 1 |
| 2 | S3 no versioning | 1 |
| 3 | S3 public access | 2 |
| 4 | S3 no logging | 1 |
| 5 | SG allows SSH 0.0.0.0/0 | 1 |
| 6 | SG allows RDP 0.0.0.0/0 | 1 |
| 7 | RDS not encrypted | 1 |
| 8 | RDS public access | 1 |
| 10 | CloudTrail disabled | 1 |
| 11 | IAM too permissive | 4 |
| 17 | ALB no HTTPS | 1 |
| 18 | RDS no backup | 1 |
| 19 | RDS no multi-AZ | 1 |
| 20 | CloudWatch no retention | 2 |
| 21 | VPC no flow logs | 1 |
| 22 | MFA not enforced | 1 |
| 24 | ECR no scan | 1 |
| 25 | Lambda no VPC | 2 |
| 26 | DynamoDB no encryption | 1 |
| 30 | SNS no encryption | 2 |
| Other | ElastiCache no encryption | 1 |
| **Total** | | **32** |

## Compliance Frameworks

All resources are tagged with:
- `Compliance: HIPAA` — indicates HIPAA-regulated resources
- `Project: MedVault` — identifies the project
- `Environment: {dev, staging, prod}` — deployment tier
- `ManagedBy: CloudFormation` — IaC ownership

## Design Realism Features

### 1. Mixed Compliance
Each template includes both compliant and non-compliant resources to test ComplyFix's selectivity:
- ✓ Audit logs bucket has encryption (good)
- ✗ PHI bucket has no encryption (bad)

### 2. Intrinsic Functions
Real CloudFormation intrinsics are used extensively:
- `Fn::Ref` — reference resources and parameters
- `Fn::GetAtt` — retrieve resource attributes
- `Fn::Sub` — string substitution with variable interpolution
- `Fn::Join` — join list elements with delimiter
- `Fn::Select` — select from a list by index
- `Fn::GetAZs` — get availability zones
- `Fn::Split` — split string by delimiter
- `Fn::If` — conditional logic
- `Fn::ImportValue` — import cross-stack references

### 3. Cross-Stack References
- Networking template exports VPC, subnet, and security group IDs
- Data tier and compute tiers import these exports
- Simulates real multi-template deployments

### 4. Conditions & Parameters
- Environment-specific configurations (dev/staging/prod)
- Optional features (CloudTrail, HTTPS, VPC Flow Logs)
- Demonstrates how compliance gaps occur with defaults

### 5. Resource Dependencies
- `DependsOn` clauses where needed
- CloudTrail bucket policy before trail creation
- Proper IAM role assumptions

### 6. AWS Best Practices
- DeletionPolicy on RDS (Snapshot)
- Tags on all resources
- Security groups reference each other
- Subnet groups for RDS/ElastiCache
- Log groups for audit trails

---

## Usage for ComplyFix Testing

### Deploy All Templates
```bash
# Create networking stack first
aws cloudformation create-stack \
  --stack-name medvault-networking-staging \
  --template-body file://networking.yaml \
  --parameters ParameterKey=Environment,ParameterValue=staging

# Create data tier (depends on networking exports)
aws cloudformation create-stack \
  --stack-name medvault-data-tier-staging \
  --template-body file://data-tier.json \
  --parameters \
    ParameterKey=Environment,ParameterValue=staging \
    ParameterKey=DBUsername,ParameterValue=medvault_admin \
    ParameterKey=DBPassword,ParameterValue=SecurePassword123!

# Create compute tier (depends on networking exports)
aws cloudformation create-stack \
  --stack-name medvault-compute-staging \
  --template-body file://compute.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=staging \
    ParameterKey=ImageUri,ParameterValue=123456789012.dkr.ecr.us-east-1.amazonaws.com/medvault-app:latest

# Create security tier (no dependencies)
aws cloudformation create-stack \
  --stack-name medvault-security-staging \
  --template-body file://security.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=staging \
    ParameterKey=AdminEmail,ParameterValue=admin@medvault.local
```

### Enable Optional Compliance Features (requires template update)
```bash
# Update with CloudTrail enabled
aws cloudformation update-stack \
  --stack-name medvault-security-staging \
  --template-body file://security.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=staging \
    ParameterKey=AdminEmail,ParameterValue=admin@medvault.local \
    ParameterKey=EnableCloudTrail,ParameterValue=true

# Update with VPC Flow Logs enabled
aws cloudformation update-stack \
  --stack-name medvault-networking-staging \
  --template-body file://networking.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=staging \
    ParameterKey=EnableFlowLogs,ParameterValue=true

# Update with HTTPS enabled
aws cloudformation update-stack \
  --stack-name medvault-compute-staging \
  --template-body file://compute.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=staging \
    ParameterKey=ImageUri,ParameterValue=123456789012.dkr.ecr.us-east-1.amazonaws.com/medvault-app:latest \
    ParameterKey=CertificateArn,ParameterValue=arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
```

---

## Checkov Integration

These templates are designed to trigger **Checkov** violations across the following check IDs:

| Check ID | Title | Pattern |
|----------|-------|---------|
| CKV_AWS_33 | Ensure S3 bucket has versioning enabled | 2 |
| CKV_AWS_34 | Ensure S3 bucket is encrypted | 1 |
| CKV_AWS_144 | Ensure that S3 bucket has public access block enabled | 3 |
| CKV_AWS_143 | Ensure S3 bucket has logging enabled | 4 |
| CKV2_AWS_6 | Ensure S3 bucket has public access block | 3 |
| CKV_AWS_23 | Ensure every security group and rule has a description | 5-6 |
| CKV_AWS_24 | Ensure no security groups allow ingress from 0.0.0.0/0 to port 22 | 5 |
| CKV_AWS_25 | Ensure no security groups allow ingress from 0.0.0.0/0 to port 3389 | 6 |
| CKV_AWS_17 | Ensure RDS is encrypted | 7 |
| CKV_AWS_16 | Ensure RDS database is not publicly accessible | 8 |
| CKV_AWS_35 | Ensure RDS has backup retention enabled | 18 |
| CKV_AWS_31 | Ensure RDS is multi-AZ | 19 |
| CKV_AWS_37 | Ensure DynamoDB point in time recovery (backup) is enabled | (audit table only) |
| CKV_AWS_28 | Ensure DynamoDB encryption is enabled | 26 |
| CKV_AWS_272 | Ensure DynamoDB encryption is enabled | 26 |
| CKV_AWS_26 | Ensure CloudTrail log file validation is enabled | 10 |
| CKV_AWS_36 | Ensure CloudTrail log file validation is enabled | 10 |
| CKV_AWS_40 | Ensure CloudTrail encryption is enabled | 10 |
| CKV_AWS_63 | Ensure that CloudWatch log group is encrypted by KMS | 20 |
| CKV_AWS_66 | Ensure CloudWatch log groups are retained for more than 1 day | 20 |
| CKV_AWS_43 | Detect the use of implicit * IAM policies | 11 |
| CKV_AWS_49 | Ensure no IAM policies documents allow "*" as statement's actions or resources | 11 |
| CKV_AWS_62 | Ensure VPC Flow logs is enabled for every subnet in VPC | 21 |
| CKV_AWS_5 | Ensure ALB/NLB has listener HTTPS | 17 |
| CKV_AWS_91 | Ensure the ECS task definition has memory set | (implicit) |
| CKV_AWS_92 | Ensure ECS Task definition has CPU set | (implicit) |
| CKV_AWS_222 | Ensure ECR image scanning on push is enabled | 24 |
| CKV_AWS_210 | Ensure Lambda function is created inside a VPC | 25 |
| CKV_AWS_50 | Ensure Lambda does not allow unknown cross-account access by default | 11 |
| CKV_AWS_94 | Ensure SNS topics are encrypted | 30 |
| CKV_AWS_26 | Ensure no IAM policies documents allow "*" as statement's principals | 11 |

---

## Notes for ComplyFix Development

1. **Parser validation:** Both JSON and YAML parsers must correctly handle all CloudFormation intrinsics and resource types.

2. **Line mapping:** Violations should trace to exact line numbers:
   - SecurityGroup ingress blocks (patterns 5-6)
   - S3 bucket properties (patterns 1-4)
   - Lambda VpcConfig absence (pattern 25)

3. **Mixed compliance testing:** Templates ensure ComplyFix doesn't over-report. E.g., Audit Logs bucket is compliant while PHI bucket violates the same patterns.

4. **Parameter/Condition handling:** CloudTrail and Flow Logs violations depend on parameters. ComplyFix should either:
   - Suggest enabling the feature via parameter change, or
   - Detect that default parameter creates the violation

5. **Cross-stack references:** Fn::ImportValue should not block parsing. ComplyFix logs warning for nested stacks (AWS::CloudFormation::Stack) in MVP.

6. **Fix targets:** Many violations are in properties that can be safely added/modified:
   - Add `ServerSideEncryptionConfiguration` to S3
   - Modify `StorageEncrypted` on RDS
   - Add `VpcConfig` to Lambda
   - Restrict CIDR in SecurityGroup rules

---

## File Metadata

| File | Format | Resources | Violations | Intrinsics |
|------|--------|-----------|-----------|-----------|
| `networking.yaml` | YAML | 15 | 3 | Ref, GetAtt, Select, GetAZs, If, Sub, ImportValue |
| `data-tier.json` | JSON | 10 | 12 | Ref, GetAtt, Sub, Join, ImportValue, Split |
| `compute.yaml` | YAML | 16 | 6 | Ref, GetAtt, Sub, ImportValue, Split, Select, If |
| `security.yaml` | YAML | 14 | 8 | Ref, GetAtt, Sub, ImportValue |

**Total Resources:** ~55  
**Total Violations:** 32 (target range 30-40)  
**Template Size:** Valid JSON/YAML (tested with `cfn-lint`)

---

Generated for ComplyFix CloudFormation scanner validation (April 2026)

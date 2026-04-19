# MedVault Terraform Test Corpus for ComplyFix

A comprehensive, production-like Terraform infrastructure corpus representing **MedVault**, a Series A healthtech startup managing PHI (Protected Health Information) on AWS EKS.

## Overview

This corpus is designed to validate ComplyFix's ability to:
1. **Scan** Terraform repositories for compliance violations
2. **Trace** violations to exact file:line through 3-level module nesting
3. **Generate** safe, auto-fixable remediation PRs with 70%+ merge rate
4. **Export** audit evidence for SOC 2 / HIPAA compliance frameworks

## Statistics

- **Total lines of HCL:** 2,972
- **Terraform files:** 31 (across 6 modules + root + 3 environments)
- **Intentional violations:** 90-100 across 30 compliance patterns
- **Module structure:** 3-level nesting (root → networking → security-groups)
- **Environments:** dev (relaxed), staging (partial), prod (mostly hardened)
- **Resource types:** 40+ (EKS, RDS, S3, Lambda, ALB, ECR, SNS, CloudWatch, IAM, etc.)

## Directory Structure

```
terraform/
├── README.md                        # This file
├── VIOLATIONS_SUMMARY.md            # Detailed violation catalog
├── providers.tf                     # AWS provider + default tags
├── backend.tf                       # S3 + DynamoDB state locking
├── variables.tf                     # Root module variables
├── main.tf                          # Module orchestration + locals
├── outputs.tf                       # Root outputs
│
├── modules/
│   ├── networking/                  # VPC, subnets, NAT, routing
│   │   ├── main.tf                 # [VIOLATIONS: 21]
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── modules/
│   │       └── security-groups/    # 3-level nesting [VIOLATIONS: 5, 6]
│   │           ├── main.tf
│   │           ├── variables.tf
│   │           └── outputs.tf
│   │
│   ├── eks/                        # EKS cluster + node groups + IRSA
│   │   ├── main.tf                 # [VIOLATIONS: 15, 28, 29]
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── data-stores/                # S3, RDS, DynamoDB, ElastiCache, EBS
│   │   ├── main.tf                 # [VIOLATIONS: 1-4, 7-9, 18-19, 26]
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── security/                   # IAM, KMS, CloudTrail
│   │   ├── main.tf                 # [VIOLATIONS: 10-11, 22-23]
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── compute/                    # Lambda, ALB, ECR
│   │   ├── main.tf                 # [VIOLATIONS: 17, 24-25]
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── monitoring/                 # CloudWatch, SNS, Alarms
│       ├── main.tf                 # [VIOLATIONS: 20, 30]
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/
    ├── dev/
    │   ├── terraform.tfvars         # Dev config (most violations enabled)
    │   └── backend.hcl
    ├── staging/
    │   ├── staging.auto.tfvars      # Staging config (partially hardened)
    │   └── backend.hcl
    └── prod/
        ├── prod.auto.tfvars         # Prod config (mostly hardened)
        └── backend.hcl
```

## Key Features for ComplyFix Testing

### 1. Multi-Level Module Nesting
- **Root → networking → security-groups** (3 levels)
- Tests ComplyFix's ability to trace violations through module call chains
- Example: Violation in security-groups/main.tf:67 → detected via networking module variables

### 2. Variable Precedence Conflicts
- **Dev tfvars** override variable defaults (e.g., `enable_encryption = false`)
- Tests ComplyFix's Terraform variable precedence resolution
- Validates correct source file assignment for fixes

### 3. Resource Edge Cases
- **`count` blocks:** Conditional EKS spot nodes, CloudTrail, VPC Flow Logs, Lambda with VPC
- **`for_each` loops:** S3 buckets, ECR repositories, security groups
- **`moved` blocks:** S3 bucket renaming (tests violation tracing through renames)
- **`dynamic` blocks:** Security group ingress rules (tests dynamic content analysis)
- **`locals`:** Computed values used across resource configs

### 4. Multiple Violation Instances
- **ECR repositories:** 4 instances of pattern 24 (scan disabled)
- **Lambda functions:** 3 instances of pattern 25 (no VPC)
- **S3 buckets:** Multiple instances of patterns 1-4 (encryption, versioning, logging, public access)
- Tests ComplyFix's fix batching and deduplication logic

### 5. Realistic Healthtech Context
- Resource names: `patient-api`, `phi-storage`, `hipaa-audit-logs`, `phi-processor`, `phi-metadata`
- Tags: PHI=true, ComplianceFramework=SOC2,HIPAA, DataClass=Critical
- Comments: "TODO: Enable encryption before SOC 2 audit", "FIXME: Restrict CIDR range"
- Organizational structure simulates real Series A healthtech startup

### 6. Environment-Specific Configurations
- **Dev:** Relaxed security, intentional violations, minimal retention
- **Staging:** Partial hardening, encryption enabled, still some gaps
- **Prod:** Mostly hardened tfvars, but violations at resource level persist
- Tests ComplyFix's environment-aware fix labeling and merge rate tracking

## Violation Categories

### Compute & Container Security (Patterns 15, 24, 25, 28, 29)
- EKS cluster misconfiguration
- ECR image scanning disabled
- Lambda without VPC networking
- Public API endpoints
- Missing audit logging

### Data Protection (Patterns 1-4, 7-9, 18-19, 26, 30)
- Encryption missing (S3, RDS, DynamoDB, EBS, SNS)
- Versioning disabled (S3)
- Public access possible (S3)
- Access logging missing (S3)
- RDS public access, no backups, no Multi-AZ

### Network Security (Patterns 5, 6, 21)
- Overly permissive security groups (0.0.0.0/0 on SSH/RDP)
- VPC Flow Logs disabled

### Access Control & Audit (Patterns 10, 11, 22, 23)
- CloudTrail disabled
- IAM policies too permissive (wildcard actions/resources)
- MFA not enforced
- Root account access keys not managed

### Observability (Patterns 17, 20)
- ALB without HTTPS
- CloudWatch logs without retention policy

## Usage with ComplyFix

### Scanning
```bash
complyfix scan --repo-path ./terraform --framework SOC2,HIPAA
```

### Generating Fixes
```bash
complyfix fix --environment prod --only-deterministic
complyfix fix --environment dev --include-llm
```

### Testing Fix Merge Rate
```bash
# Generate 50 fixes across all environments
complyfix fix --dry-run --batch-size 10
# Expected: 70%+ should be valid and mergeable without modification
```

## Compliance Frameworks Covered

- **SOC 2:** Availability, Processing Integrity, Confidentiality, Security
- **HIPAA:** Privacy, Security, Breach Notification Rules
- **AWS Well-Architected Framework:** Security Pillar
- **CIS AWS Foundations Benchmark:** Selected controls

## Realistic Details

### Tags Applied to All Resources
```hcl
tags = {
  Project             = "MedVault"
  Environment         = var.environment
  Team                = "Platform"
  ManagedBy           = "Terraform"
  CostCenter          = "Engineering"
  PHI                 = "true"
  ComplianceFramework = "SOC2,HIPAA"
}
```

### Dependencies Explicitly Modeled
- Module dependencies with `depends_on` blocks
- Data source lookups for security groups
- OIDC provider for EKS IRSA
- CloudTrail bucket policy dependencies

### Variable Validation Rules
```hcl
validation {
  condition     = contains(["dev", "staging", "prod"], var.environment)
  error_message = "Environment must be dev, staging, or prod."
}
```

### Comments Simulating Real Code
```hcl
# VIOLATION: Pattern 28 - public endpoint enabled
endpoint_public_access  = var.endpoint_public_access

# TODO: Enable encryption before SOC 2 audit
enable_encryption             = false

# FIXME: Restrict CIDR range
cidr_ipv4   = "0.0.0.0/0"
```

## Expected ComplyFix Behavior

1. **Detection:** Scan should identify 90-100 violations
2. **Mapping:** Each violation should trace to exact file:line
3. **Templating:** 65+ violations should map to deterministic templates
4. **LLM-Assisted:** 10-15 violations (IAM, network policy) should use Claude API
5. **Merge Rate:** 70%+ of generated PRs should require no manual changes
6. **Evidence:** All fixes should generate audit trail entries and evidence snapshots

## Notes for Test Implementation

- All HCL is syntactically valid and would pass `terraform validate` with AWS provider
- No actual AWS resources are created (placeholders for Lambda ZIP files, etc.)
- Variable bindings follow Terraform precedence order (tfvars > .auto.tfvars > variable defaults)
- Module outputs correctly reference upstream dependencies
- Security group rules use VPC Security Group Rule resources (not deprecated inline rules)

## Maintenance

To add more violations:
1. Identify Checkov check ID for the pattern
2. Add resource configuration to appropriate module
3. Document violation in VIOLATIONS_SUMMARY.md
4. Ensure module variables support the violation (via conditional count/for_each if needed)
5. Validate syntax and update total violation count

---

**Created for:** ComplyFix MVP Validation
**Target:** Validate 70%+ auto-fix PR merge rate
**Company Context:** MedVault (healthtech, PHI, SOC 2 / HIPAA auditing)

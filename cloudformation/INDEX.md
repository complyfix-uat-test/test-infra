# MedVault CloudFormation Test Corpus — Index

This directory contains a comprehensive test corpus for ComplyFix's CloudFormation scanner. It simulates a realistic healthtech startup (**MedVault**) managing AWS infrastructure with 32 intentional compliance violations.

## Quick Start

### File Overview
| File | Type | Lines | Purpose |
|------|------|-------|---------|
| **networking.yaml** | CloudFormation (YAML) | 611 | VPC, subnets, security groups (3 violations) |
| **data-tier.json** | CloudFormation (JSON) | 639 | S3, RDS, DynamoDB, ElastiCache (12 violations) |
| **compute.yaml** | CloudFormation (YAML) | 635 | ALB, ECS, Lambda, ECR (6 violations) |
| **security.yaml** | CloudFormation (YAML) | 532 | IAM, CloudTrail, KMS, CloudWatch, SNS (8 violations + 3 other) |
| **README.md** | Documentation | 374 | Comprehensive guide to all templates |
| **VIOLATIONS.md** | Documentation | 1004 | Detailed mapping of each violation |
| **MANIFEST.txt** | Checklist | 180+ | Validation checklist and usage instructions |
| **INDEX.md** | Navigation | This file | Quick reference guide |

## Violation Summary

**Total: 32 violations** across **21 patterns**

- **Critical (6):** Patterns 5, 6, 7, 8, 11a
- **High (6):** Patterns 1, 10, 17, 26, 30
- **Medium (20):** Patterns 2, 3, 4, 11b-d, 18-25, ElastiCache

## Files to Read

### For Understanding the Violations
1. Start with **README.md** — High-level overview and architecture
2. Then **VIOLATIONS.md** — Detailed mapping with exact line locations and fixes

### For Implementation
1. Review each `.yaml` or `.json` template
2. Cross-reference violations in VIOLATIONS.md
3. Use MANIFEST.txt for validation checklist

### For Deployment/Testing
1. Follow instructions in README.md deployment section
2. Use MANIFEST.txt as validation checklist

## Key Design Features

### 1. Multi-Format Testing
- **JSON format:** `data-tier.json` — tests JSON parser
- **YAML format:** 3 templates — tests YAML parser with CloudFormation intrinsics

### 2. Intrinsic Functions (11 types used)
```
Ref, Fn::GetAtt, Fn::Sub, Fn::Join, Fn::Select, Fn::GetAZs, 
Fn::Split, Fn::If, Fn::ImportValue, Fn::Equals, Fn::Not
```

### 3. Cross-Stack References
Templates export resources that others import, testing dependency resolution.

### 4. Mixed Compliance
Some resources compliant, others violating — tests selectivity.

### 5. Real-World Architecture
- Multi-tier VPC with HA
- ECS Fargate with ALB
- RDS PostgreSQL with failover
- ElastiCache for caching
- CloudTrail audit logging
- Proper security group isolation

## Compliance Violations by Pattern

| # | Pattern | File | Count | Severity |
|---|---------|------|-------|----------|
| 1 | S3 no encryption | data-tier.json | 1 | HIGH |
| 2 | S3 no versioning | data-tier.json | 1 | MEDIUM |
| 3 | S3 public access | data-tier.json | 2 | MEDIUM |
| 4 | S3 no logging | data-tier.json | 1 | MEDIUM |
| 5 | SG SSH 0.0.0.0/0 | networking.yaml | 1 | CRITICAL |
| 6 | SG RDP 0.0.0.0/0 | networking.yaml | 1 | CRITICAL |
| 7 | RDS not encrypted | data-tier.json | 1 | CRITICAL |
| 8 | RDS public | data-tier.json | 1 | CRITICAL |
| 10 | CloudTrail disabled | security.yaml | 1 | HIGH |
| 11 | IAM overly permissive | compute.yaml, security.yaml | 4 | CRITICAL |
| 17 | ALB no HTTPS | compute.yaml | 1 | HIGH |
| 18 | RDS no backup | data-tier.json | 1 | MEDIUM |
| 19 | RDS no Multi-AZ | data-tier.json | 1 | MEDIUM |
| 20 | CloudWatch no retention | security.yaml | 2 | MEDIUM |
| 21 | VPC no Flow Logs | networking.yaml | 1 | MEDIUM |
| 22 | MFA not enforced | security.yaml | 1 | MEDIUM |
| 24 | ECR no scan | compute.yaml | 1 | MEDIUM |
| 25 | Lambda no VPC | compute.yaml | 2 | MEDIUM |
| 26 | DynamoDB no encryption | data-tier.json | 1 | HIGH |
| 30 | SNS no KMS | security.yaml | 2 | MEDIUM |
| Other | ElastiCache no encryption | data-tier.json | 1 | MEDIUM |

## Expected Test Results

When ComplyFix scans these templates:

1. **Parser validation**
   - ✓ Reads both JSON and YAML
   - ✓ Understands all CloudFormation intrinsics
   - ✓ Resolves cross-stack exports

2. **Violation detection**
   - ✓ 32 total findings
   - ✓ Correct severity levels
   - ✓ Exact line:column mappings

3. **Fix generation**
   - ✓ Deterministic fixes (add properties, modify values)
   - ✓ Does not modify compliant resources
   - ✓ Respects code style (indentation, formatting)

4. **Evidence mapping**
   - ✓ Links findings to compliance frameworks (HIPAA, SOC2)
   - ✓ Traces control IDs to Checkov checks
   - ✓ Includes resource details (ARN, type, tags)

## Resource Count

| Category | Count |
|----------|-------|
| Total AWS Resources | ~55 |
| VPCs | 1 |
| Security Groups | 5 |
| Subnets | 6 |
| S3 Buckets | 4 |
| RDS Instances | 1 |
| DynamoDB Tables | 2 |
| Lambda Functions | 3 |
| ECS Resources | 4 |
| IAM Roles | 8 |
| Total Lines of Code | 3,795 |
| Documentation Lines | 1,700+ |

## Checkov Integration

These templates trigger **~23 Checkov check IDs**:

**Critical:**
- CKV_AWS_24 (SG SSH open)
- CKV_AWS_25 (SG RDP open)
- CKV_AWS_40 (IAM * permissions)

**High:**
- CKV_AWS_5 (ALB HTTPS)
- CKV_AWS_16 (RDS public)
- CKV_AWS_17 (RDS encryption)
- CKV_AWS_34 (S3 encryption)

**Medium:**
- CKV_AWS_26 (CloudTrail)
- CKV_AWS_28 (DynamoDB encryption)
- CKV_AWS_31 (RDS Multi-AZ)
- CKV_AWS_33 (S3 versioning)
- CKV_AWS_35 (RDS backup)
- CKV_AWS_62 (VPC Flow Logs)
- CKV_AWS_66 (CloudWatch retention)
- CKV_AWS_143 (S3 logging)
- CKV_AWS_144 (S3 public block)
- CKV_AWS_210 (Lambda VPC)
- CKV_AWS_222 (ECR scanning)
- CKV_AWS_272 (DynamoDB PITR)
- CKV_AWS_94 (SNS encryption)
- Plus others...

## How to Use This Corpus

### 1. Validation Testing
```bash
# Scan with ComplyFix
complyfix scan --framework cloudformation --path .

# Compare results against VIOLATIONS.md
```

### 2. Parser Testing
```bash
# Test JSON parser
python3 -m json.tool data-tier.json

# Test YAML parser (with custom CF intrinsic handling)
# See VIOLATIONS.md for expected structures
```

### 3. Integration Testing
```bash
# Deploy to AWS (requires AWS credentials)
aws cloudformation create-stack --stack-name medvault-networking-staging \
  --template-body file://networking.yaml

# Scan deployed resources
complyfix scan --framework cloudformation --account-id 123456789012
```

### 4. Fix Generation Testing
```bash
# For each violation, verify fix generation
# Pattern 1 (S3 encryption): ComplyFix should add ServerSideEncryptionConfiguration
# Pattern 5 (SG SSH): ComplyFix should restrict CIDR or add source security group
# etc.
```

## Design Principles

✓ **Realistic** — Mirrors actual healthtech infrastructure  
✓ **Complete** — Full working templates (can deploy to AWS)  
✓ **Comprehensive** — 32 violations across multiple resource types  
✓ **Educational** — Demonstrates CloudFormation best practices and anti-patterns  
✓ **Testable** — Deterministic violations, repeatable scan results  
✓ **Documented** — Extensive guides and violation mappings  

## Next Steps

1. **Read README.md** for architecture overview
2. **Review VIOLATIONS.md** for detailed violation locations
3. **Scan templates** with ComplyFix
4. **Compare results** against expected violations
5. **Test fix generation** for each pattern
6. **Validate** with `cfn-lint` or AWS CLI

---

**Created:** April 16, 2026  
**For:** ComplyFix CloudFormation Scanner  
**Scenario:** MedVault Healthtech Startup  
**Compliance Focus:** HIPAA, SOC 2

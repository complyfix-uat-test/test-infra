# MedVault Infrastructure

> Production infrastructure for MedVault, a healthtech platform managing Protected Health Information (PHI) on AWS.

## Overview

MedVault runs on AWS EKS with Terraform-managed infrastructure, Helm-deployed microservices, and some legacy CloudFormation stacks. We are preparing for our first SOC 2 Type II and HIPAA audit (target: Q4 2026).

**Stack:** AWS EKS / Terraform / Helm / CloudFormation / GitHub

## Repository Structure

```
.
├── terraform/              # Primary IaC — AWS infrastructure
│   ├── modules/            # Reusable modules (networking, EKS, data, security, compute, monitoring)
│   ├── environments/       # Per-environment tfvars (dev, staging, prod)
│   ├── main.tf             # Root module
│   └── ...
├── helm/                   # Kubernetes workloads
│   ├── patient-api/        # Main application (with Redis + PostgreSQL subcharts)
│   ├── internal-tools/     # Admin dashboard
│   └── common/             # Shared library chart
├── cloudformation/         # Legacy CF stacks (networking, data-tier, compute, security)
│   ├── networking.yaml
│   ├── data-tier.json
│   ├── compute.yaml
│   └── security.yaml
└── Makefile                # Build/scan/deploy commands
```

## Quick Start

```bash
# Scan for compliance violations
make scan-all

# Terraform
make tf-init ENV=dev
make tf-plan ENV=dev

# Helm
make helm-lint
make helm-template ENV=prod
```

## Compliance Status

**Current state:** Pre-audit. Multiple known violations across S3 encryption, IAM policies, EKS hardening, and Kubernetes pod security. Remediation in progress.

**Frameworks:** SOC 2 (CC series), HIPAA (Administrative + Technical Safeguards)

## Team

- **Infrastructure:** 2 engineers
- **Security:** 1 engineer (part-time, shared with product)
- **Compliance:** External vCISO (fractional, 10 hrs/month)

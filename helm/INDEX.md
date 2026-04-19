# ComplyFix Helm Chart Test Corpus - Complete Index

## Quick Links

- **Main Documentation:** [README.md](README.md)
- **Violation Checklist:** [VIOLATIONS_CHECKLIST.md](VIOLATIONS_CHECKLIST.md)
- **File Structure:** [STRUCTURE.md](STRUCTURE.md)
- **Delivery Summary:** [DELIVERY_SUMMARY.txt](DELIVERY_SUMMARY.txt)

## Directory Structure

```
helm/
├── Documentation (4 files)
│   ├── INDEX.md (this file)
│   ├── README.md (full guide with usage)
│   ├── VIOLATIONS_CHECKLIST.md (violations with line numbers)
│   ├── STRUCTURE.md (file inventory and layout)
│   └── DELIVERY_SUMMARY.txt (executive summary)
│
├── Common Library Chart (1 chart, 3 files)
│   └── common/
│       ├── Chart.yaml (library v0.2.0)
│       └── templates/
│           ├── _helpers.tpl (shared helpers)
│           └── _pod.tpl (reusable pod spec)
│
├── Patient-API Chart (1 chart, 14 files)
│   └── patient-api/
│       ├── Chart.yaml (application v1.4.0)
│       ├── values.yaml (base - 28 violations)
│       ├── values-dev.yaml (dev environment)
│       ├── values-staging.yaml (staging environment)
│       ├── values-prod.yaml (production environment)
│       └── templates/ (8 template files)
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── hpa.yaml
│           ├── serviceaccount.yaml
│           ├── configmap.yaml
│           ├── secrets.yaml
│           └── _helpers.tpl
│
└── Internal-Tools Chart (1 chart, 7 files)
    └── internal-tools/
        ├── Chart.yaml (application v0.8.0)
        ├── values.yaml (base - 12 violations)
        ├── values-prod.yaml (production)
        └── templates/ (5 template files)
            ├── deployment.yaml
            ├── service.yaml
            ├── rbac.yaml
            ├── networkpolicy.yaml
            └── _helpers.tpl
```

**Total: 28 files, 3 charts, ~44 violations**

## Chart Overview

### Common (Library Chart)
- **Purpose:** Shared templates and helpers for all MedVault charts
- **Version:** 0.2.0 (Helm v3)
- **Files:** 3 (Chart.yaml + 2 templates)
- **Violations:** 0 (library only provides helpers)
- **Key Content:**
  - Shared label and selector helpers
  - Reusable pod spec template
  - Standard security context defaults

### Patient-API (Main Application)
- **Purpose:** Patient data API microservice with compliance controls
- **Version:** 1.4.0 (Helm v3)
- **Files:** 14 (Chart.yaml + 4 values + 8 templates + 1 helper)
- **Violations:** ~32 (across base and subcharts)
- **Environments:** dev, staging, prod (separate values files)
- **Dependencies:**
  - common (v0.2.0, local)
  - redis (Bitnami v17.11.3)
  - postgresql (Bitnami v12.1.2)
- **Key Content:**
  - Multi-replica deployment with probes
  - ConfigMap and Secret management
  - AWS ALB Ingress
  - Horizontal Pod Autoscaler
  - ServiceAccount with IRSA annotation
  - Secret storage (unencrypted)

**Violations by Type:**
- No pod security context (8)
- No resource limits (10 - main + subcharts)
- No network policy (6)
- Missing TLS (4)
- Secrets not encrypted (3)
- No PDB (4)

### Internal-Tools (Admin Dashboard)
- **Purpose:** Admin operational dashboard and troubleshooting tools
- **Version:** 0.8.0 (Helm v3)
- **Files:** 7 (Chart.yaml + 2 values + 5 templates + 1 helper)
- **Violations:** ~12 (critical RBAC and privilege issues)
- **Environments:** base and prod
- **Key Content:**
  - Privileged container (intentional violation)
  - Running as root (intentional violation)
  - RBAC with wildcard permissions (intentional violation)
  - NetworkPolicy template (disabled via values)
  - NodePort service (intentional violation)

**Violations by Type:**
- Running as root (5)
- RBAC too broad (2)
- No resource limits (2)
- No network policy (2)
- Missing probes (1)
- NodePort service (1)

## Violation Statistics

### By Severity

| Severity | Count | Examples |
|----------|-------|----------|
| CRITICAL | 3 | runAsUser: 0, privileged: true, wildcard RBAC |
| HIGH | ~20 | No runAsNonRoot, no network policy, missing TLS |
| MEDIUM | ~12 | No resource limits, partial security context |
| INFO | ~4 | No PDB, no probes, NodePort service |

### By Pattern

| Pattern | Count | Pattern Name |
|---------|-------|--------------|
| 12 | 13 | Pod Running as Root / No runAsNonRoot |
| 13 | 12 | No Resource Limits |
| 14 | 8 | No Network Policy |
| 16 | 3 | Secrets Not Encrypted |
| 17 | 4 | Ingress TLS Missing |
| 27 | 2 | RBAC Too Broad |
| Other | 4 | PDB, probes, service type |

### By Chart

| Chart | Violations | Primary Issues |
|-------|-----------|-----------------|
| patient-api | ~32 | Security contexts, resource limits, TLS, subcharts |
| internal-tools | ~12 | Privileged mode, RBAC, probes |
| common | 0 | N/A (library only) |

## Testing Capabilities

### 1. Value Tracing
- Multiple environment values files
- Subchart value nesting (redis.master.resources)
- Value merging and precedence
- Default dict handling

### 2. Violation Detection
- Empty security contexts
- Missing required fields
- Disabled features via values
- Wildcard RBAC permissions
- Incomplete TLS configuration

### 3. Multi-Environment
- Dev (relaxed, single replica)
- Staging (partial hardening)
- Prod (max hardening, but violations remain)

### 4. Fix Patterns
- Template-driven deterministic fixes
- LLM-assisted contextual fixes
- Manual review items

## File Locations

### Documentation
- `README.md` — Main guide and usage
- `VIOLATIONS_CHECKLIST.md` — All violations with line numbers
- `STRUCTURE.md` — File inventory and layouts
- `DELIVERY_SUMMARY.txt` — Executive summary
- `INDEX.md` — This file

### Common Chart
- `common/Chart.yaml`
- `common/templates/_helpers.tpl`
- `common/templates/_pod.tpl`

### Patient-API Chart
- `patient-api/Chart.yaml`
- `patient-api/values.yaml`
- `patient-api/values-dev.yaml`
- `patient-api/values-staging.yaml`
- `patient-api/values-prod.yaml`
- `patient-api/templates/deployment.yaml`
- `patient-api/templates/service.yaml`
- `patient-api/templates/ingress.yaml`
- `patient-api/templates/hpa.yaml`
- `patient-api/templates/serviceaccount.yaml`
- `patient-api/templates/configmap.yaml`
- `patient-api/templates/secrets.yaml`
- `patient-api/templates/_helpers.tpl`

### Internal-Tools Chart
- `internal-tools/Chart.yaml`
- `internal-tools/values.yaml`
- `internal-tools/values-prod.yaml`
- `internal-tools/templates/deployment.yaml`
- `internal-tools/templates/service.yaml`
- `internal-tools/templates/rbac.yaml`
- `internal-tools/templates/networkpolicy.yaml`
- `internal-tools/templates/_helpers.tpl`

## Getting Started

### 1. Read Documentation
```bash
# Start with overview
cat README.md

# Check violations
cat VIOLATIONS_CHECKLIST.md

# Review structure
cat STRUCTURE.md
```

### 2. Validate Charts
```bash
# Lint all charts
helm lint common/
helm lint patient-api/
helm lint internal-tools/
```

### 3. Render Templates
```bash
# Update dependencies
cd patient-api && helm dependency update

# Render base values
helm template medvault patient-api/ -f values.yaml

# Render prod values
helm template medvault patient-api/ -f values-prod.yaml

# Render internal-tools
helm template medvault internal-tools/ -f values.yaml
```

### 4. Test with ComplyFix
```bash
# Scan for violations
complyfix scan --repo-path . --iac-type helm

# Scan specific environment
complyfix scan --repo-path patient-api --iac-type helm --values-file values-prod.yaml

# Generate fixes (dry-run)
complyfix fix --repo-path . --iac-type helm --dry-run

# Generate fixes for specific chart
complyfix fix --repo-path patient-api --iac-type helm --dry-run
```

## Key Features

✓ **Realistic Context:** MedVault healthtech startup with PHI handling
✓ **Valid YAML:** All files pass Helm lint
✓ **Multi-Environment:** Dev, staging, prod with proper overrides
✓ **Subcharts:** Tests value tracing with Bitnami dependencies
✓ **Documentation:** Comprehensive with violations clearly marked
✓ **Test Scenarios:** 5+ scenarios for ComplyFix validation
✓ **Compliance Tags:** HIPAA and SOC 2 framework annotations

## File Statistics

| Metric | Value |
|--------|-------|
| Total Files | 28 |
| Total Size | 148 KB |
| Charts | 3 |
| Template Files | 15 |
| Values Files | 6 |
| Documentation Files | 4 |
| Violations | ~44 |
| Helm Versions | v3 (apiVersion: v2) |

## Next Steps

1. **Review README.md** for complete overview
2. **Check VIOLATIONS_CHECKLIST.md** for specific violations
3. **Run helm lint** to validate syntax
4. **Run helm template** to see rendered output
5. **Test with ComplyFix** scan and fix commands

---

**Last Updated:** 2026-04-16
**Status:** Ready for Testing
**Version:** 1.0

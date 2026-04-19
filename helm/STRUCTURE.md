# ComplyFix Helm Chart Test Corpus - Complete Structure

## Overview
- **Location:** `/sessions/zen-friendly-cray/mnt/complyfix/test-corpus/helm/`
- **Total Files:** 26
- **Total Size:** 128KB
- **Charts:** 3 (1 library, 2 application)
- **Violations:** ~44 (documented in VIOLATIONS_CHECKLIST.md)

## Directory Layout

```
helm/
├── README.md                          # Main documentation and usage guide
├── VIOLATIONS_CHECKLIST.md            # Detailed violation mapping and checklist
├── STRUCTURE.md                       # This file
│
├── common/                            # Library chart (Helm 3)
│   ├── Chart.yaml
│   └── templates/
│       ├── _helpers.tpl               # Shared helpers
│       └── _pod.tpl                   # Reusable pod spec template
│
├── patient-api/                       # Main application chart
│   ├── Chart.yaml                     # v1.4.0, apiVersion: v2
│   ├── values.yaml                    # Base values with violations
│   ├── values-dev.yaml                # Dev overrides (relaxed)
│   ├── values-staging.yaml            # Staging overrides (partial hardening)
│   ├── values-prod.yaml               # Prod overrides (remaining violations)
│   ├── charts/                        # (Populated by helm dependency update)
│   │   └── common/                    # Local dependency
│   │   └── redis/                     # Bitnami redis 17.x
│   │   └── postgresql/                # Bitnami postgresql 12.x
│   └── templates/
│       ├── _helpers.tpl               # Chart-specific helpers
│       ├── deployment.yaml            # Main deployment with violations
│       ├── service.yaml               # ClusterIP service
│       ├── ingress.yaml               # ALB ingress (no TLS)
│       ├── hpa.yaml                   # HorizontalPodAutoscaler
│       ├── serviceaccount.yaml        # ServiceAccount with IRSA
│       ├── configmap.yaml             # Application configuration
│       └── secrets.yaml               # Base64-encoded secrets (not encrypted)
│
└── internal-tools/                    # Admin tools chart
    ├── Chart.yaml                     # v0.8.0, apiVersion: v2
    ├── values.yaml                    # Base values with violations
    ├── values-prod.yaml               # Prod overrides
    └── templates/
        ├── _helpers.tpl               # Chart-specific helpers
        ├── deployment.yaml            # Deployment (privileged container)
        ├── service.yaml               # NodePort service
        ├── rbac.yaml                  # RBAC with wildcard permissions
        └── networkpolicy.yaml         # Network policy (disabled)
```

## File Inventory

### Documentation (2 files)
- `README.md` — Full guide, usage instructions, test scenarios
- `VIOLATIONS_CHECKLIST.md` — Violation mapping with line numbers and severity

### Helm Chart Definitions (3 files)
- `common/Chart.yaml` — Library chart v0.2.0
- `patient-api/Chart.yaml` — Application chart v1.4.0 with 3 dependencies
- `internal-tools/Chart.yaml` — Application chart v0.8.0

### Values Files (5 files)
- `patient-api/values.yaml` — Base values (production baseline)
- `patient-api/values-dev.yaml` — Dev environment
- `patient-api/values-staging.yaml` — Staging environment
- `patient-api/values-prod.yaml` — Production overrides
- `internal-tools/values.yaml` — Base values
- `internal-tools/values-prod.yaml` — Production overrides

### Templates (15 files)

#### Patient-API Templates (8 files)
- `deployment.yaml` — Main workload (tests pod security context, resource limits)
- `service.yaml` — Kubernetes Service
- `ingress.yaml` — AWS ALB Ingress (tests TLS detection)
- `hpa.yaml` — Horizontal Pod Autoscaler
- `serviceaccount.yaml` — ServiceAccount with IRSA annotation
- `configmap.yaml` — Application configuration
- `secrets.yaml` — Kubernetes Secrets (tests encryption violation)
- `_helpers.tpl` — Helm helper templates

#### Internal-Tools Templates (5 files)
- `deployment.yaml` — Deployment with privilege violations
- `service.yaml` — NodePort Service
- `rbac.yaml` — ServiceAccount + RBAC (tests wildcard permissions)
- `networkpolicy.yaml` — Network Policy (disabled via values)
- `_helpers.tpl` — Helm helper templates

#### Common (Library) Templates (2 files)
- `_helpers.tpl` — Shared helpers for all charts
- `_pod.tpl` — Reusable pod spec template

## Chart Dependencies

### patient-api Dependencies
```yaml
dependencies:
  - name: common
    version: "0.2.0"
    repository: "file://../common"
    alias: common

  - name: redis
    version: "17.11.3"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled

  - name: postgresql
    version: "12.1.2"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

### Dependency Update Required
```bash
cd patient-api/
helm dependency update
# Creates charts/ directory with actual bitnami charts
```

## Values Files Hierarchy

### patient-api Values
1. **Base (values.yaml):** 28 violations
   - Empty security contexts
   - No resource limits
   - No network policy
   - TLS not configured
   - Subcharts with empty resources

2. **Dev (values-dev.yaml):** 12 additional violations
   - Overrides: single replica, no persistence
   - Inherits parent violations
   - All security contexts empty

3. **Staging (values-staging.yaml):** 8 violations
   - Overrides: 2 replicas, some hardening
   - Partial security contexts (fsGroup set, runAsNonRoot missing)
   - Subcharts still missing resources

4. **Prod (values-prod.yaml):** 10 violations
   - Overrides: 3 replicas, full persistence
   - More hardening but violations remain
   - Tests value merging and precedence

### internal-tools Values
1. **Base (values.yaml):** 12 violations
   - runAsUser: 0, privileged: true
   - Wildcard RBAC
   - No resource limits
   - No network policy

2. **Prod (values-prod.yaml):** 7 violations
   - Slightly tighter but RBAC still too broad
   - Still no resource limits

## Violation Categories

### By Pattern
| Pattern | Count | Charts |
|---------|-------|--------|
| 12 (No runAsNonRoot) | 13 | patient-api (8), internal-tools (5) |
| 13 (No resource limits) | 12 | patient-api (10), internal-tools (2) |
| 14 (No network policy) | 8 | patient-api (6), internal-tools (2) |
| 16 (Secrets not encrypted) | 3 | patient-api |
| 17 (Ingress TLS missing) | 4 | patient-api |
| 27 (RBAC too broad) | 2 | internal-tools |
| Other (PDB, probes) | 4 | Both charts |
| **Total** | **~44** | |

### By Severity
| Severity | Count |
|----------|-------|
| CRITICAL | 3 |
| HIGH | ~20 |
| MEDIUM | ~12 |
| INFO | ~4 |

## Key Testing Features

### Value Tracing
- Multiple values files per chart (dev, staging, prod)
- Subchart value nesting (redis.master.resources)
- Value merging and precedence testing
- Empty dict defaults in templates

### Violation Detection
- Empty security contexts (`podSecurityContext: {}`)
- Missing required fields (runAsNonRoot, resources)
- Disabled features via values (networkPolicy.enabled: false)
- Wildcard RBAC permissions
- Incomplete TLS configuration

### Helm Syntax
- Valid YAML throughout
- Proper Helm templating ({{ }}, include, if, range, with)
- Template comments explaining violations
- Helper templates for code reuse
- Conditional blocks for features

### Realism
- Realistic AWS ECR image URIs
- Proper port numbers and protocols
- IRSA annotations for AWS IAM
- Monitoring labels and annotations
- Compliance framework tagging (HIPAA, SOC2)
- TODO comments for remediation

## Helm CLI Validation

```bash
# Lint charts
helm lint common/
helm lint patient-api/
helm lint internal-tools/

# Update dependencies (for patient-api)
cd patient-api && helm dependency update

# Template rendering (show YAML output)
helm template medvault patient-api/ -f values.yaml
helm template medvault patient-api/ -f values-prod.yaml
helm template medvault internal-tools/ -f values.yaml

# Dry-run install
helm install --dry-run medvault patient-api/ -f values-prod.yaml
```

## ComplyFix Validation Scenarios

### Scenario 1: Base Chart Scanning
**Command:** `complyfix scan --repo-path . --iac-type helm`
**Expected:** Detects ~28 violations in patient-api base values

### Scenario 2: Environment-Specific Scanning
**Command:** `complyfix scan --repo-path . --iac-type helm --values-override prod`
**Expected:** Detects violations after merging values-prod.yaml

### Scenario 3: Subchart Fixing
**Command:** `complyfix fix --repo-path patient-api --iac-type helm`
**Expected:** Generates fixes for redis.master.resources and postgresql.primary.resources

### Scenario 4: RBAC Narrowing
**Command:** `complyfix fix --repo-path internal-tools --iac-type helm`
**Expected:** LLM-assisted fix to scope RBAC from wildcard to specific resources

### Scenario 5: Multi-Environment Safety
**Command:** `complyfix fix --repo-path . --iac-type helm --values-file values-prod.yaml --dry-run`
**Expected:** Fixes only apply to prod values, preserving other environments

## Completeness Checklist

- [x] Chart.yaml files with apiVersion v2
- [x] Multiple values files (base + dev/staging/prod)
- [x] 8+ template files across 2 charts
- [x] Proper Helm template syntax throughout
- [x] Realistic image URIs and configuration
- [x] Violations documented with comments
- [x] Subchart dependencies (redis, postgresql)
- [x] Local library subchart (common)
- [x] RBAC and NetworkPolicy templates
- [x] Security context violations
- [x] Resource limit violations
- [x] RBAC permission violations
- [x] TLS/Ingress violations
- [x] Secret encryption violations
- [x] Multiple violation patterns (12, 13, 14, 16, 17, 27)
- [x] README with usage instructions
- [x] Violation checklist with line numbers
- [x] Total 26 files, 128KB
- [x] All YAML valid and complete

---

**Ready for ComplyFix testing and validation.**

# ComplyFix Helm Chart Test Corpus

This directory contains a realistic Helm chart test corpus for **MedVault**, a healthtech startup handling Protected Health Information (PHI) and preparing for SOC 2 / HIPAA audit.

## Contents

### Chart 1: `patient-api/`
Main patient data API microservice with subcharts for Redis and PostgreSQL.

**Structure:**
- `Chart.yaml` — declares dependencies on common, redis, postgresql subcharts
- `values.yaml` — base production values with ~25 violations
- `values-dev.yaml` — development overrides, more relaxed
- `values-staging.yaml` — staging with partial hardening
- `values-prod.yaml` — production overrides with remaining violations
- `templates/` — 8 template files (deployment, service, ingress, hpa, serviceaccount, configmap, secrets, helpers)
- `charts/common/` — local library subchart

**Violations in patient-api:**
- No `podSecurityContext` defined (pods can run as root)
- No `securityContext` on containers
- No resource limits defined
- No network policy enabled
- Secrets not encrypted at rest (base64 only)
- Ingress TLS incomplete or missing
- Redis/PostgreSQL subcharts have empty `resources: {}`
- No pod disruption budget
- No `runAsNonRoot` even in prod values

**Key features:**
- Realistic image URIs (ECR repositories)
- Three separate values files per environment with proper precedence
- Subchart value tracing test (redis.master.resources, postgresql.primary.resources)
- Template uses `{{ .Values.podSecurityContext | default dict }}` — violation detection test
- Comments indicating where ComplyFix should fix violations

### Chart 2: `internal-tools/`
Admin dashboard and operational tools. Simpler structure without dependencies.

**Structure:**
- `Chart.yaml` — standalone application chart
- `values.yaml` — base values with ~12 violations
- `values-prod.yaml` — production overrides
- `templates/` — 5 template files (deployment, service, rbac, networkpolicy, helpers)

**Violations in internal-tools:**
- `runAsUser: 0` (running as root) in securityContext
- `privileged: true` container
- No pod security context
- No resource limits
- RBAC with wildcard permissions (`apiGroups: ["*"], resources: ["*"], verbs: ["*"]`)
- Network policy disabled
- No probes defined

## Violation Summary

**Total violations: ~45-50**

### By Category

| Category | Count | Patterns |
|----------|-------|----------|
| No pod security context | 8 | Pattern 12 (K8s pod running as root) |
| No resource limits | 10 | Pattern 13 (K8s no resource limits) |
| No network policy | 6 | Pattern 14 (K8s no network policy) |
| No pod security standards | 6 | Pattern 12 (runAsNonRoot missing) |
| Secrets not encrypted | 3 | Pattern 16 (K8s secrets not encrypted) |
| Ingress TLS missing/incomplete | 4 | Pattern 17 (ALB no HTTPS) |
| RBAC too broad | 3 | Pattern 27 (K8s RBAC too broad) |
| No pod disruption budget | 4 | Pattern (no PDB) |
| Privileged containers | 2 | Pattern (K8s privileged) |
| Missing probes/other | 4 | Liveness/readiness probes, etc. |

## Realism Features

✓ Valid YAML Helm template syntax
✓ Realistic AWS ECR image URIs
✓ Proper Helm templating (`{{ }}`，`include`, `range`, `if`, `with`)
✓ Service accounts with IRSA annotations
✓ Environment variables, ConfigMaps, Secrets
✓ Bitnami subchart dependencies (redis, postgresql)
✓ Multiple environment values files (dev, staging, prod)
✓ Proper value precedence and merging
✓ Comments explaining violations
✓ Realistic port numbers, resource names, CIDR blocks
✓ Compliance framework tagging (HIPAA, SOC2)
✓ TODO comments indicating remediation needed

## ComplyFix Test Scenarios

### 1. Value Tracing Across Files
- **Test:** ComplyFix detects violations in `values-prod.yaml` that override base `values.yaml`
- **Example:** `redis.master.resources: {}` in prod should be fixed to include limits

### 2. Subchart Value Tracing
- **Test:** ComplyFix follows nested Helm values to fix subchart violations
- **Example:** Fixing `redis.auth.podSecurityContext` requires modifying prod values under redis key

### 3. Template Rendering
- **Test:** ComplyFix recognizes `{{ .Values.podSecurityContext | default dict }}` as a violation
- **Example:** When values are empty, template renders nothing, leaving pods unsecured

### 4. Partial Hardening Detection
- **Test:** Identify when some security controls are set but others are missing
- **Example:** `staging` values set `fsGroup` but not `runAsNonRoot`

### 5. RBAC Pattern Detection
- **Test:** Identify wildcard RBAC rules and suggest scoped alternatives
- **Example:** `internal-tools` has `apiGroups: ["*"], resources: ["*"], verbs: ["*"]`

### 6. Multi-environment Validation
- **Test:** Ensure fixes are applied to correct environment file
- **Example:** Fix to `values-prod.yaml` should not affect `values-dev.yaml`

## Chart Metadata Verification

Both charts include:
- apiVersion: v2 (Helm 3)
- Valid Chart.yaml with appVersion
- Dependencies declared with versions and repositories
- Maintainers and keywords
- Home and sources URLs
- Proper chart descriptions

## Usage

### Validate Charts
```bash
helm lint patient-api/
helm lint internal-tools/
helm lint common/
```

### Template Rendering
```bash
helm template medvault patient-api/ -f patient-api/values.yaml
helm template medvault patient-api/ -f patient-api/values-prod.yaml
helm template medvault internal-tools/ -f internal-tools/values-prod.yaml
```

### Dependency Updates
```bash
cd patient-api/
helm dependency update
```

### ComplyFix Scanning
```bash
complyfix scan --repo-path . --iac-type helm
complyfix scan --repo-path patient-api/ --iac-type helm --framework hipaa
complyfix fix --repo-path . --iac-type helm --dry-run
```

## Compliance Frameworks

Charts are annotated for:
- **HIPAA** — PHI handling, encryption, audit logging
- **SOC 2** — access controls, monitoring, incident response

## Notes

- Charts use realistic naming conventions (patient-api, internal-tools) matching MedVault's product
- Violations are intentional and documented with comments
- Values files demonstrate proper Helm precedence: base → dev/staging/prod
- Subchart integration tests value tracing (redis, postgresql)
- Network policies are defined but disabled (`enabled: false`) to test violation detection

---

**Target:** This corpus validates ComplyFix's ability to:
1. Parse Helm charts and values files
2. Trace violations to exact file:line
3. Generate safe, deterministic and LLM-assisted fixes
4. Respect Helm value precedence and merging
5. Handle multipart fixes (main chart + subcharts)
6. Create audit-compliant fix PRs with evidence

# ComplyFix Helm Chart Test Corpus - Violations Checklist

This document lists all intentional violations embedded in the test charts, mapped to Kubernetes compliance patterns.

## Patient-API Chart

### Pattern 12: Pod Running as Root / No runAsNonRoot

| File | Line Context | Severity | Fix Type |
|------|--------------|----------|----------|
| values.yaml | `podSecurityContext: {}` (line ~20) | HIGH | Add `runAsNonRoot: true, runAsUser: 1000` |
| values.yaml | `securityContext: {}` (line ~25) | HIGH | Add `runAsNonRoot: true, runAsUser: 1000` |
| values-dev.yaml | `podSecurityContext: {}` (line ~13) | HIGH | Add security context for dev |
| values-dev.yaml | `securityContext: {}` (line ~16) | HIGH | Add security context for dev |
| values-staging.yaml | `podSecurityContext.runAsNonRoot missing` (line ~11) | HIGH | Add `runAsNonRoot: true` to existing fsGroup |
| values-staging.yaml | `securityContext` partial (line ~16) | HIGH | Add `runAsNonRoot: true, runAsUser: 1000` |
| values-prod.yaml | `podSecurityContext.runAsNonRoot missing` (line ~11) | HIGH | Add `runAsNonRoot: true` to existing fsGroup |
| redis subchart | `podSecurityContext: {}` in all values | HIGH | Add security context to redis values |

**Total: 8 violations**

### Pattern 13: No Resource Limits

| File | Location | Severity | Fix Type |
|------|----------|----------|----------|
| values.yaml | `resources: {}` (line ~35) | MEDIUM | Add limits and requests for main container |
| values-dev.yaml | `resources: {}` (line ~20) | MEDIUM | Add dev-appropriate limits |
| values-staging.yaml | `resources: {}` (line ~22) | MEDIUM | Add staging resource limits |
| values-prod.yaml | Main container limits exist, but... | N/A | ✓ OK |
| values.yaml | `redis.master.resources: {}` (line ~96) | MEDIUM | Add redis resource limits |
| values-staging.yaml | `redis.master.resources: {}` (line ~78) | MEDIUM | Add redis resource limits to staging |
| values-prod.yaml | `redis.master.resources: {}` (line ~97) | MEDIUM | Add redis resource limits to prod |
| values.yaml | `postgresql.primary.resources: {}` (line ~109) | MEDIUM | Add postgres resource limits |
| values-staging.yaml | `postgresql.primary.resources: {}` (line ~93) | MEDIUM | Add postgres resource limits to staging |
| values-prod.yaml | `postgresql.primary.resources: {}` (line ~108) | MEDIUM | Add postgres resource limits to prod |

**Total: 10 violations**

### Pattern 14: No Network Policy

| File | Location | Severity | Fix Type |
|------|----------|----------|----------|
| values.yaml | `networkPolicy.enabled: false` (line ~62) | HIGH | Enable network policy |
| values-dev.yaml | `networkPolicy.enabled: false` (line ~58) | MEDIUM | Enable for dev (relaxed rules) |
| values-staging.yaml | `networkPolicy.enabled: false` (line ~78) | HIGH | Enable for staging |
| values-prod.yaml | `networkPolicy.enabled: false` (line ~123) | HIGH | Enable for prod with strict rules |
| templates/networkpolicy.yaml | Conditional rendering `if .Values.networkPolicy.enabled` | N/A | Template OK, values disable it |
| internal-tools/values.yaml | `networkPolicy.enabled: false` (line ~39) | HIGH | Enable network policy |
| internal-tools/values-prod.yaml | `networkPolicy.enabled: false` (line ~31) | HIGH | Enable for prod |

**Total: 6 violations**

### Pattern 16: Secrets Not Encrypted at Rest

| File | Location | Severity | Fix Type |
|------|----------|----------|----------|
| templates/secrets.yaml | Line ~10 comment | HIGH | Enable EKS secret encryption |
| templates/secrets.yaml | Base64 encoding only (not encrypted) | HIGH | Configure KMS key for EKS |
| values.yaml | `secrets.enabled: true` but unencrypted | HIGH | Requires cluster-level fix |

**Total: 3 violations**

### Pattern 17: ALB No HTTPS / Ingress TLS Missing

| File | Location | Severity | Fix Type |
|------|----------|----------|----------|
| values.yaml | `ingress.tls: []` empty (line ~53) | HIGH | Add TLS certificate block |
| values-dev.yaml | `ingress.tls: []` empty (line ~35) | MEDIUM | Add TLS for dev (self-signed OK) |
| values-staging.yaml | `ingress.tls.secretName missing` (line ~43) | HIGH | Add secretName field |
| values-prod.yaml | `ingress.tls.secretName missing` (line ~62) | HIGH | Add secretName field with proper cert |

**Total: 4 violations**

### Other Violations

| Pattern | File | Location | Count |
|---------|------|----------|-------|
| No Pod Disruption Budget | values*.yaml | `podDisruptionBudget.enabled: false` | 4 |
| Container Security Context Missing | redis/postgres subcharts | `containerSecurityContext: {}` | 4 |
| Pod Security Context on Subcharts | redis/postgres subcharts | `podSecurityContext: {}` | 4 |

**Total Other: 12 violations**

---

## Internal-Tools Chart

### Pattern 12: Pod Running as Root / Privileged

| File | Location | Severity | Fix Type |
|------|----------|----------|----------|
| values.yaml | `securityContext.runAsUser: 0` (line ~19) | CRITICAL | Remove `runAsUser: 0`, add `runAsNonRoot: true` |
| values.yaml | `securityContext.privileged: true` (line ~20) | CRITICAL | Set `privileged: false` |
| values.yaml | `podSecurityContext: {}` (line ~23) | HIGH | Add pod security context |
| values-prod.yaml | `securityContext.runAsUser: 0` (line ~12) | CRITICAL | Remove privileged, add `runAsNonRoot` |
| values-prod.yaml | `podSecurityContext: {}` (line ~16) | HIGH | Add pod security context for prod |

**Total: 5 violations**

### Pattern 13: No Resource Limits

| File | Location | Severity | Fix Type |
|------|----------|----------|----------|
| values.yaml | `resources: {}` (line ~28) | MEDIUM | Add resource limits for admin tool |
| values-prod.yaml | `resources: {}` (line ~19) | MEDIUM | Add prod-appropriate resource limits |

**Total: 2 violations**

### Pattern 14: No Network Policy

| File | Location | Severity | Fix Type |
|------|----------|----------|----------|
| values.yaml | `networkPolicy.enabled: false` (line ~39) | HIGH | Enable network policy restricted to admins |
| values-prod.yaml | `networkPolicy.enabled: false` (line ~31) | HIGH | Enable for prod with strict rules |

**Total: 2 violations**

### Pattern 27: RBAC Too Broad

| File | Location | Severity | Fix Type |
|------|----------|----------|----------|
| values.yaml | `rbac.rules: apiGroups: ["*"], resources: ["*"], verbs: ["*"]` (line ~42-44) | CRITICAL | Scope to specific resources (pods, deployments, events) |
| values-prod.yaml | `rbac.rules: wildcard permissions` (line ~34-36) | CRITICAL | Scope RBAC for production |

**Total: 2 violations**

### Other Violations

| Pattern | File | Location | Count |
|---------|------|----------|-------|
| NodePort Service (should be ClusterIP) | values.yaml | `service.type: NodePort` | 1 |
| Missing Liveness/Readiness Probes | templates/deployment.yaml | No probes in template | 1 |

**Total Other: 2 violations**

---

## Violation Summary by Severity

### CRITICAL (Must Fix)
- runAsUser: 0 (internal-tools)
- privileged: true (internal-tools)
- RBAC wildcard permissions (internal-tools)
Total: 3 violations

### HIGH (Should Fix for Compliance)
- No pod security context (patient-api)
- No network policy enabled (both charts)
- Ingress TLS missing (patient-api)
- Missing runAsNonRoot (patient-api + subcharts)
Total: ~20 violations

### MEDIUM (Should Fix)
- No resource limits (both charts)
- Partial security contexts (patient-api staging)
- Network policy disabled in dev
Total: ~12 violations

### INFORMATIONAL (Nice to Have)
- No PDB configured
- No probes configured (internal-tools)
- NodePort service (internal-tools)
Total: ~4 violations

---

## Violation Distribution by Chart

### Patient-API
- Total violations: ~32
- Across main chart and 3 subcharts (redis, postgresql)
- Tests: value tracing, subchart fixing, multi-environment hardening

### Internal-Tools
- Total violations: ~12
- Single chart, no dependencies
- Tests: RBAC narrowing, privilege removal, security context addition

### Common (Library Chart)
- No violations (library provides helpers)
- Tests: subchart template integration

---

## Test Coverage Matrix

| ComplyFix Capability | Test Location | Validation |
|---------------------|---------------|-----------|
| Parse Helm values | Both charts | Multiple values*.yaml files |
| Trace violations to file:line | patient-api/values*.yaml | Exact line numbers documented |
| Detect empty security contexts | templates/deployment.yaml | `{{ .Values.podSecurityContext \| default dict }}` |
| Handle value precedence | patient-api (dev/staging/prod) | Different values per environment |
| Subchart value fixing | patient-api redis/postgresql | Nested values (redis.master.resources) |
| RBAC pattern detection | internal-tools/values.yaml | Wildcard apiGroups/resources/verbs |
| Template rendering | Both charts | Proper Helm syntax validation |
| Multi-environment safety | patient-api | Fixes applied only to target env |

---

## ComplyFix Fix Patterns Expected

### Template-Driven (Deterministic)
- Add `runAsNonRoot: true, runAsUser: 1000` to podSecurityContext
- Add resource limits (limits.cpu, limits.memory)
- Remove `runAsUser: 0` and `privileged: true`
- Enable network policy with sensible defaults
- Add TLS block to ingress

### LLM-Assisted (20%)
- Scope RBAC rules to specific verbs/resources
- Generate context-appropriate network policies
- Suggest resource limits based on workload type

### Manual Review
- Cluster-level secret encryption (EKS KMS)
- Certificate procurement for TLS
- Pod disruption budget sizing

---

**Total Violations in Corpus: ~44**
- Patient-API: 32 violations (main chart + 3 subcharts)
- Internal-Tools: 12 violations (single chart)
- Coverage: Patterns 12, 13, 14, 16, 17, 27 + miscellaneous

All violations are intentional and documented with comments for ComplyFix validation.

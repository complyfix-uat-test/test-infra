{{/*
Common helpers for all MedVault charts
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for compliance and tracking
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
medvault.io/compliance: "true"
medvault.io/monitoring: "true"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Standard pod security context - can be overridden by parent charts
*/}}
{{- define "common.podSecurityContext" -}}
{{- $default := dict "runAsNonRoot" true "runAsUser" 1000 "fsGroup" 1000 }}
{{- toYaml (merge (.Values.podSecurityContext | default dict) $default) }}
{{- end }}

{{/*
Standard container security context
*/}}
{{- define "common.securityContext" -}}
{{- $default := dict "allowPrivilegeEscalation" false "readOnlyRootFilesystem" true "runAsNonRoot" true "runAsUser" 1000 "capabilities" (dict "drop" (list "ALL")) }}
{{- toYaml (merge (.Values.securityContext | default dict) $default) }}
{{- end }}

{{/*
Standard resource limits
*/}}
{{- define "common.resources" -}}
{{- $defaults := dict "limits" (dict "cpu" "100m" "memory" "128Mi") "requests" (dict "cpu" "50m" "memory" "64Mi") }}
{{- toYaml (merge (.Values.resources | default dict) $defaults) }}
{{- end }}

{{/*
Environment variables for audit logging
*/}}
{{- define "common.auditEnvVars" -}}
- name: AUDIT_LOGGING_ENABLED
  value: "true"
- name: AUDIT_LOG_LEVEL
  value: "INFO"
- name: COMPLIANCE_FRAMEWORK
  value: "HIPAA,SOC2"
{{- end }}

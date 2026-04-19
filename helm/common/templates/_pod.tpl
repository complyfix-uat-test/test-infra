{{/*
Reusable pod spec template for all MedVault microservices
This template demonstrates value tracing across subcharts
*/}}
{{- define "common.podSpec" -}}
spec:
  serviceAccountName: {{ include "common.serviceAccountName" . }}
  {{- with .Values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  # Pod security context from global values or parent chart
  securityContext:
    {{- if .Values.global.podSecurityContext }}
    {{- toYaml .Values.global.podSecurityContext | nindent 4 }}
    {{- else }}
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    {{- end }}
  containers:
  - name: {{ .Chart.Name }}
    # Container security context
    securityContext:
      {{- toYaml .Values.securityContext | nindent 6 }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    ports:
    - name: http
      containerPort: 8080
      protocol: TCP
    livenessProbe:
      httpGet:
        path: /health
        port: http
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: http
      initialDelaySeconds: 10
      periodSeconds: 5
    # Resource limits - required by compliance frameworks
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

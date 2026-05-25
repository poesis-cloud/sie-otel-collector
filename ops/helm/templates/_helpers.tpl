{{- define "sie-otel-collector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sie-otel-collector.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "sie-otel-collector.name" . -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "sie-otel-collector.labels" -}}
app.kubernetes.io/name: {{ include "sie-otel-collector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: otel-collector
{{- end -}}

{{/*
ADR-001 D-1 DNS contract is enforced as a warning (not a template `fail`)
in `NOTES.txt` and as a CI grep check on the rendered Service in
`.github/workflows/ci.yaml`. This preserves operator escape hatches
(blue/green, sidecar tests) while still surfacing accidental overrides.
*/}}

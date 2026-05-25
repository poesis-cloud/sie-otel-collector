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
ADR-001 D-1 DNS contract guard: the in-cluster Service name MUST be
`sie-otel-collector` so consumers can resolve
`sie-otel-collector.<namespace>.svc.cluster.local:4317`. Fail render if
the operator tries to override it.
*/}}
{{- define "sie-otel-collector.assertServiceName" -}}
{{- if ne .Values.service.name "sie-otel-collector" -}}
{{- fail (printf "service.name MUST be 'sie-otel-collector' (ADR-001 D-1 DNS contract); got %q" .Values.service.name) -}}
{{- end -}}
{{- end -}}

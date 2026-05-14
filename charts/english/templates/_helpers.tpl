{{/*
Expand the name of the chart.
*/}}
{{- define "english.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart label
*/}}
{{- define "english.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "english.labels" -}}
helm.sh/chart: {{ include "english.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

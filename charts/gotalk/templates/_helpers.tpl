{{/*
Expand the name of the chart.
*/}}
{{- define "gotalk.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart label
*/}}
{{- define "gotalk.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gotalk.labels" -}}
helm.sh/chart: {{ include "gotalk.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

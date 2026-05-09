{{/*
Expand the name of the chart.
*/}}
{{- define "cv.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart label
*/}}
{{- define "cv.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cv.labels" -}}
helm.sh/chart: {{ include "cv.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

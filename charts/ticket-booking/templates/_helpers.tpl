{{/*
Create chart label.
*/}}
{{- define "ticket-booking.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "ticket-booking.labels" -}}
helm.sh/chart: {{ include "ticket-booking.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "romm.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "romm.labels" -}}
{{ include "romm.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{/* The chart's claims: the values key, the default name's suffix and the mount path, in mount order. */}}
{{- define "romm.claims" -}}
- key: resources
  suffix: resources
  mountPath: /romm/resources
- key: assets
  suffix: assets
  mountPath: /romm/assets
- key: redisData
  suffix: redis-data
  mountPath: /redis-data
{{- end }}

{{- define "romm.claimName" -}}
{{- $persistence := index .root.Values.persistence .claim.key -}}
{{ $persistence.claimName | default (printf "%s-%s" .root.Release.Name .claim.suffix) }}
{{- end }}

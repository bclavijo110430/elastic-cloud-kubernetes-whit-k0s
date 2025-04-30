{{/*
Nombre corto del chart, truncado a 63 caracteres (límite DNS).
Permite sobreescribir con .Values.nameOverride.
*/}}
{{- define "eck_quiron.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Nombre completo del release, siguiendo la convención <release>-<chart>.
Permite sobreescribir con .Values.fullnameOverride.
Trunca a 63 caracteres para cumplir con restricciones de Kubernetes.
*/}}
{{- define "eck_quiron.fullname" -}}
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
Nombre del chart junto con la versión, útil para etiquetas.
Reemplaza "+" por "_" para evitar problemas en nombres de recursos.
*/}}
{{- define "eck_quiron.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Etiquetas comunes recomendadas por Helm y Kubernetes.
Incluye nombre, instancia, versión, y gestor del release.
*/}}
{{- define "eck_quiron.labels" -}}
helm.sh/chart: {{ include "eck_quiron.chart" . }}
{{ include "eck_quiron.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Etiquetas de selector estándar para identificar recursos de la app.
*/}}
{{- define "eck_quiron.selectorLabels" -}}
app.kubernetes.io/name: {{ include "eck_quiron.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Devuelve el nombre de la ServiceAccount a usar.
Permite crear una nueva o usar una existente según .Values.serviceAccount.
*/}}
{{- define "eck_quiron.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "eck_quiron.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Helper para anotar recursos con anotaciones globales definidas en values.yaml.
Uso: {{ include "eck_quiron.globalAnnotations" . }}
*/}}
{{- define "eck_quiron.globalAnnotations" -}}
{{- with .Values.annotations }}
{{- toYaml . | nindent 4 }}
{{- end }}
{{- end }}

{{/*
Helper para obtener el namespace destino, configurable desde values.yaml.
Uso: {{ include "eck_quiron.namespace" . }}
*/}}
{{- define "eck_quiron.namespace" -}}
{{- default "default" .Values.annotations.namespace }}
{{- end }}
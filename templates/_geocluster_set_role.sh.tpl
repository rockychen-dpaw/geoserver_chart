{{- define "geocluster.set_role" }}#!/bin/bash
{{- $adminServerIsWorker :=  true }}
{{- if hasKey $.Values.geoserver "adminServerIsWorker" }}
  {{- $adminServerIsWorker =  $.Values.geoserver.adminServerIsWorker }}
{{- end }}

{{- if $adminServerIsWorker }}
if [[ "${HOSTNAME}" == "{{ $.Release.Name }}-geocluster-0" ]]; then
  GEOCLUSTER_ROLE="admin&worker"
else
  GEOCLUSTER_ROLE="slave"
fi
{{- else }}
if [[ "${HOSTNAME}" == "{{ $.Release.Name }}-geocluster-"* ]]; then
  GEOCLUSTER_ROLE="slave"
else
  GEOCLUSTER_ROLE="admin"
fi
{{- end }}
echo "GEOCLUSTER_ROLE=${GEOCLUSTER_ROLE}"
export GEOCLUSTER_ROLE
{{- end }}

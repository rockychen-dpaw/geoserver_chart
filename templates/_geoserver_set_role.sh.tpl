{{- define "geoserver.set_role" }}#!/bin/bash
{{- if and $.Values.geoserver ($.Values.geoserver.clustering | default false) }}
  {{- $adminServerIsWorker :=  true }}
  {{- if hasKey $.Values.geoserver "adminServerIsWorker" }}
    {{- $adminServerIsWorker =  $.Values.geoserver.adminServerIsWorker }}
  {{- end }}

  {{- if $adminServerIsWorker }}
if [[ "${HOSTNAME}" == "{{ $.Release.Name }}-geocluster-0" ]]; then
  GEOSERVER_ROLE="admin&worker"
else
  GEOSERVER_ROLE="slave"
fi
  {{- else }}
if [[ "${HOSTNAME}" == "{{ $.Release.Name }}-geocluster-"* ]]; then
  GEOSERVER_ROLE="slave"
else
  GEOSERVER_ROLE="admin"
fi
  {{- end }}
{{- else }}
GEOSERVER_ROLE="server"
{{- end }}
export GEOSERVER_ROLE
{{- end }}

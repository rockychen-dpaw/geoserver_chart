{{- define "geoserver.geoserver_liveness" }}#!/bin/bash
{{- $log_levels := dict "DISABLE" 0 "ERROR" 100 "WARNING" 200 "INFO" 300 "DEBUG" 400 }}
{{- $log_levelname := upper ($.Values.geoserver.healthchecklog | default "DISABLE") }}
{{- if not (hasKey $log_levels $log_levelname) }}
{{- $log_levelname = "DISABLE" }}
{{- end }}
{{- $log_level := (get $log_levels $log_levelname) | int }}
wget --tries=1 --timeout=0.5 http://127.0.0.1:8080/geoserver/web -o /dev/null -O /dev/null
status=$?
{{- if ge $log_level ((get $log_levels "ERROR") | int) }}
if [[ ${status} -gt 0 ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Startup : Geoserver is offline" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
{{- if ge $log_level ((get $log_levels "DEBUG") | int) }}
else
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Startup : Geoserver is online" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
{{- end }}
fi
{{- end }}
exit $status
{{- end }}


{{- define "geoserver.geoserver_liveness" }}#!/bin/bash
{{- $log_levels := dict "DISABLE" 0 "ERROR" 100 "WARNING" 200 "INFO" 300 "DEBUG" 400 }}
{{- $log_levelname := upper ($.Values.geoserver.livenesslog | default "DISABLE") }}
{{- if not (hasKey $log_levels $log_levelname) }}
{{- $log_levelname = "DISABLE" }}
{{- end }}
{{- $log_level := (get $log_levels $log_levelname) | int }}
wget --tries=1 --timeout={{$.Values.geoserver.liveCheckTimeout | default 0.5 }} http://127.0.0.1:8080/geoserver/www/serverinfo.html -o /dev/null -O /dev/null
status=$?
{{- if ge $log_level ((get $log_levels "ERROR") | int) }}
{{- if gt ($.Values.geoserver.memoryMonitorInterval | default 0 | int) 0  }}
geoserverpid=$(cat /tmp/geoserverpid)
nexttime=$(cat /tmp/memorymonitornexttime)
if [[ $(date '+%s') -ge ${nexttime} ]] ; then
  printf -v memoryusage "%%CPU: %s , Virtual Memory: %sMB , Physical Memory: %sMB" $(ps -o %cpu=,vsz=,rss= ${geoserverpid} | awk '{printf "%.1f %.0f %.0f",$1,$2/1024,$3/1024}')
  echo "$((${nexttime} + {{- $.Values.geoserver.memoryMonitorInterval}}))" > /tmp/memorymonitornexttime
elif [[ ${status} -gt 0 ]]; then
  printf -v memoryusage "%%CPU: %s , Virtual Memory: %sMB , Physical Memory: %sMB" $(ps -o %cpu=,vsz=,rss= ${geoserverpid} | awk '{printf "%.1f %.0f %.0f",$1,$2/1024,$3/1024}')
else
  memoryusage=""
fi
{{- else }}
memoryusage=""
{{- end }}
if [[ ${status} -gt 0 ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is offline. ${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/liveness.log
{{- if ge $log_level ((get $log_levels "DEBUG") | int) }}
else
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is online. ${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/liveness.log
{{- else }}
elif [[ "${memoryusage}" != "" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is online. ${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/liveness.log
{{- end }}
fi

if [[ "${memoryusage}" != "" ]]; then
  sed -i "s/<span id=\"monitortime\">[^<]*<\/span>/<span id=\"monitortime\">$(date '+%Y-%m-%d %H:%M:%S')<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html
  sed -i "s/<span id=\"resourceusage\">[^<]*<\/span>/<span id=\"resourceusage\">${memoryusage}<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html
fi

{{- end }}
exit $status
{{- end }}


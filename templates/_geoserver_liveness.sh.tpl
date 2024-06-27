{{- define "geoserver.geoserver_liveness" }}#!/bin/bash
{{- if and ($.Values.geoserver.clustering | default false) (gt ($.Values.geoserver.replicas | default 1) 1) (get $.Values.geoserver "restartPolicy") (get $.Values.geoserver.restartPolicy "restartSchedule") }}
if [[ -f ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime ]]; then
  nextRestartSeconds=$(cat ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime)
  now=$(date '+%Y-%m-%d %H:%M:%S')
  seconds=$(date -d "${now}" '+%s')
  if [[ ${seconds} -ge ${nextRestartSeconds} ]]; then
    #need to restart
    source ${GEOSERVER_HOME}/bin/restart_period.sh
    i=0
    canRestart=0
    while [[ $i -lt ${#restartPeriod[@]} ]]; do
      if [[ ${hour} -ge ${restartPeriod[${i}]} ]] && [[ ${hour} -lt ${restartPeriod[$((${i} + 1))]} ]]; then
         #in restart period
         canRestart=1
      else
        i=$(($i + 2))
      fi
    done
    if [[ ${canRestart} -eq 1 ]]; then
      #can restart
      #check whether the other servers are online and also it has the earliest restart time
      status=0
      {{- range $i,$index := until $.Values.geoserver.replicas | default 1 }}
      if [[ "{{ $.Release.Name}}-geocluster-{{$i}}" =! "${HOSTNAME}" ]] && [[ ${status} -eq 0 ]]; then
        {{- if eq $i 0 }}
        wget --timeout=0.5 http://{{$.Release.Name}}-geoclusteradmin:8080/geoserver/web -o /tmp/geoserver_healthcheck.log -O /tmp/geoserver_healthcheck.html 
        {{- else }}
        wget --timeout=0.5 http://{{$.Release.Name}}-geoclusterslave{{$i}}:8080/geoserver/web -o /tmp/geoserver_healthcheck.log -O /tmp/geoserver_healthcheck.html
        {{- end }}
      fi
      status=$((${status} + $?))
      {{- end }}
    fi
  fi
fi

{{- end}}
wget http://127.0.0.1:8080/geoserver/web -o /tmp/geoserver_healthcheck.log -O /tmp/geoserver_healthcheck.html
exit $?
{{- end }}


{{- define "geocluster.geoserver_liveness" }}#!/bin/bash
{{- if and (gt ($.Values.geoserver.replicas | default 1) 1) (get $.Values.geoserver "restartPolicy") (get $.Values.geoserver.restartPolicy "restartSchedule") }}
if [[ -f ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime ]]; then
  nextRestartSeconds=$(cat ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime)
  now=$(date '+%Y-%m-%d %H:%M:%S')
  seconds=$(date -d "${now}" '+%s')
  if [[ ${seconds} -ge ${nextRestartSeconds} ]]; then
    #need to restart
    declare -a restartPeriods
    {{- if get $.Values.geoserver.restartPolicy "restartPeriods" }}
      {{- $index := 0}}
      {{- range $i,$config := $.Values.geoserver.restartPolicy.restartPeriods }}
    restartPeriods[{{mul $i  2}}]={{ $config.startHour }}
    restartPeriods[{{add (mul $i  2)  1}}]={{ $config.endHour }}
      {{- end }}
    {{- else }}
    restartPeriods[0]=0
    restartPeriods[1]=24
    {{- end }}
    {{- end }}
    i=0
    canRestart=0
    while [[ $i -lt ${#restartPeriods[@]} ]]; do
      if [[ ${hour} -ge ${restartPeriods[${i}]} ]] && [[ ${hour} -lt ${restartPeriods[$((${i} + 1))]} ]]; then
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
        wget --user ${GEOSERVER_ADMIN_USER} --password ${GEOSERVER_ADMIN_PASSWORD} --timeout=0.5 http://{{$.Release.Name}}-geoclusteradmin:8080/geoserver/www/server/nextrestarttime -o /tmp/remotegeoserver_nextrestarttime.log -O /tmp/remotegeoserver_nextrestarttime
        {{- else }}
        wget --user ${GEOSERVER_ADMIN_USER} --password ${GEOSERVER_ADMIN_PASSWORD} --timeout=0.5 http://{{$.Release.Name}}-geoclusterslave{{$i}}:8080/geoserver/www/server/nextrestarttim    e -o /tmp/remotegeoserver_nextrestarttime.log -O /tmp/remotegeoserver_nextrestarttime
        {{- end }}
        status=$((${status} + $?))
        if [[ $status -eq 0 ]]; then
          remotegeoserverNextRestartTime=$(cat /tmp/remotegeoserver_nextrestarttime)
          if [[ ${remotegeoserverNextRestartTime=} -lt ${nextRestartSeconds} ]]; then
              #remote geoserver should be restarted before this geoserver
              #can't restart this geoserver now
              status=99
          fi
        fi
      fi
      {{- end }}
      if [[ $status -eq 0 ]]; then
        #try to restart this geoserver
        exit 1
      fi
    fi
  fi
fi
{{- end}}
wget http://127.0.0.1:8080/geoserver/web -o /tmp/geoserver_healthcheck.log -O /tmp/geoserver_healthcheck.html
status=$?
if [[ ${status} -eq 0 ]]; then
  rm -f /tmp/geoserver_failuretimes
  exit 0
fi
if [[ -f /tmp/geoserver_failuretimes ]]; then
  failureTimes=$(cat /tmp/geoserver_failuretimes)
  failureTimes=$((${failureTimes} + 1))
else
  failureTimes=1
fi
echo ${failureTimes} > /tmp/geoserver_failuretimes
if [[ ${failureTimes} -ge {{ $livenessProbe.failureThreshold | default 2 }} ]]; then
  #geoserver is not available
  exit ${status}
else
  exit 0
fi
{{- end }}

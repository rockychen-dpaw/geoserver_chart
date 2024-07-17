{{- define "geocluster.geoserver_liveness" }}#!/bin/bash
{{- $log_levels := dict "DISABLE" 0 "ERROR" 100 "WARNING" 200 "INFO" 300 "DEBUG" 400 }}
{{- $log_levelname := upper ($.Values.geoserver.healthchecklog | default "DISABLE") }}
{{- if not (hasKey $log_levels $log_levelname) }}
{{- $log_levelname = "DISABLE" }}
{{- end }}
{{- $log_level := (get $log_levels $log_levelname) | int }}
{{- $livenessProbe :=  $.Values.geoserver.livenessProbe | default dict }}
{{- if and (gt ($.Values.geoserver.replicas | default 1 | int) 1) (get $.Values.geoserver "restartPolicy") (get $.Values.geoserver.restartPolicy "restartSchedule") }}
if [[ -f ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime ]]; then
  nextRestartSeconds=$(cat ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime)
  now=$(date '+%Y-%m-%d %H:%M:%S')
  hour=$(date -d "${now}" '+%H')
  hour="${hour#0*}"
  seconds=$(date -d "${now}" '+%s')

  {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
  #manage  healthcheck log
  if [[ -f ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log ]] && [[ ${hour} -eq 1 ]]; then
    minute=$(date -d "${now}" '+%M')
    if [[ ${minute} -lt 2 ]]; then
      #only manage the healthcheck log between 1:00:00 and 1:01:59
      rows=$(cat ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log | wc -l )
      if [[ ${rows} -gt 10000 ]]; then
        firstrow=1
        lastrow=$((${rows} - 10000))
        sed -i -e "${firstrow},${lastrow}d" ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
        status=$((${status} + $?))
      fi
    fi
  fi 
  {{- end }}

  if [[ ${seconds} -ge ${nextRestartSeconds} ]]; then
    #need to restart
    {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is scheduled to restart at $(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')." >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
    {{- end }}
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
    i=0
    canRestart=0
    while [[ $i -lt ${#restartPeriods[@]} ]]; do
      if [[ ${hour} -ge ${restartPeriods[${i}]} ]] && [[ ${hour} -lt ${restartPeriods[$((${i} + 1))]} ]]; then
         #in restart period
         canRestart=1
         break
      else
        i=$(($i + 2))
      fi
    done
    if [[ ${canRestart} -eq 1 ]]; then
      #can restart
      #check whether the other servers are online and also it has the earliest restart time
      {{- if ge $log_level ((get $log_levels "INFO") | int) }}
      echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : check whether it is safe to restart the geoserver." >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
      {{- end }}
      status=0
      {{- range $i,$index := until ($.Values.geoserver.replicas | default 1 | int) }}
      if [[ "{{ $.Release.Name}}-geocluster-{{$i}}" != "${HOSTNAME}" ]] && [[ ${status} -eq 0 ]]; then
        {{- if eq $i 0 }}
        server="{{$.Release.Name}}-geoclusteradmin"
        {{- else }}
        server="{{$.Release.Name}}-geoclusterslave{{$i}}"
        {{- end }}
        wget --tries=1 --user=${GEOSERVER_ADMIN_USER} --password=${GEOSERVER_ADMIN_PASSWORD} --timeout=0.5 http://${server}:8080/geoserver/www/server/nextrestarttime -o /dev/null -O /tmp/remotegeoserver_nextrestarttime
        status=$((${status} + $?))
        if [[ $status -eq 0 ]]; then
          remoteGeoserverNextRestartTime=$(cat /tmp/remotegeoserver_nextrestarttime)
          if [[ ${remoteGeoserverNextRestartTime} -lt ${nextRestartSeconds} ]]; then
            #remote geoserver should be restarted before this geoserver
            #can't restart this geoserver now
            status=99
            {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
            echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: The remote geoserver(http://${server}:8080/geoserver) is online and its next restart time is $(date -d @${remoteGeoserverNextRestartTime} '+%Y-%m-%d %H:%M:%S') which is earlier than the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')), Can't restart." >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
            {{- end }}
          elif [[ ${remoteGeoserverNextRestartTime} -eq ${nextRestartSeconds} ]]; then
            index="${HOSTNAME#{{ $.Release.Name }}-geocluster-*}"
            if [[ ${index} -gt {{$i}} ]]; then
              status=99
              {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
              echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: The remote geoserver(http://${server}:8080/geoserver) is online and its next restart time is $(date -d @${remoteGeoserverNextRestartTime} '+%Y-%m-%d %H:%M:%S') which is equal with the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')), but the server index(${index}) is greater than the remote geoserver index({{$i}}), Can't restart." >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
              {{- end }}
            {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
            else
              echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: The remote geoserver(http://${server}:8080/geoserver) is online and its next restart time is $(date -d @${remoteGeoserverNextRestartTime} '+%Y-%m-%d %H:%M:%S') which is equal with the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')), but the server index(${index}) is less than the remote geoserver index({{$i}}), can restart before the remote geoserver." >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
            {{- end }}
            fi
          {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
          else
            echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : The remote geoserver(http://${server}:8080/geoserver) is online and its next restart time is $(date -d @${remoteGeoserverNextRestartTime} '+%Y-%m-%d %H:%M:%S') which is later than the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')), can restart before the remote geoserver." >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
          {{- end }}
          fi
        {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
        else
          echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : The remote geoserver(http://${server}:8080/geoserver) is offline(status=${status})." >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
        {{- end }}
        fi
      fi
      {{- end }}
      if [[ $status -eq 0 ]]; then
        #try to restart this geoserver
        {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
          {{- if gt ($.Values.geoserver.memoryMonitorInterval | default 0 | int) 0  }}
        geoserverpid=$(cat /tmp/geoserverpid)
        printf -v memoryusage "Virtual Memory: %sMB , Physical Memory: %sMB" $(ps -o vsz=,rss= ${geoserverpid} | awk '{printf "%.0f %.0f", $1/1024,$2/1024}')
          {{- else }}
        memoryusage=""
          {{- end }}
        echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: All remote geoservers are online and also their next restart time are earlier than the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')). Try to restart the current geoserver. ${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
        {{- end }}
        exit 1
      {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
      else
        echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : It is not safe to restart the geoserver right now" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
      {{- end }}
      fi
    fi
  fi
fi
{{- end}}
wget --tries=1 --timeout=0.5 http://127.0.0.1:8080/geoserver/web -o /dev/null -O /dev/null
status=$?
{{- if ge $log_level ((get $log_levels "ERROR") | int) }}
{{- if gt ($.Values.geoserver.memoryMonitorInterval | default 0 | int) 0  }}
geoserverpid=$(cat /tmp/geoserverpid)
nexttime=$(cat /tmp/memorymonitornexttime)
if [[ $(date '+%s') -ge ${nexttime} ]] ; then
  printf -v memoryusage "Virtual Memory: %sMB , Physical Memory: %sMB" $(ps -o vsz=,rss= ${geoserverpid} | awk '{printf "%.0f %.0f", $1/1024,$2/1024}')
  echo "$((${nexttime} + {{- $.Values.geoserver.memoryMonitorInterval}}))" > /tmp/memorymonitornexttime
elif [[ ${status} -gt 0 ]]; then
  printf -v memoryusage "Virtual Memory: %sMB , Physical Memory: %sMB" $(ps -o vsz=,rss= ${geoserverpid} | awk '{printf "%.0f %.0f", $1/1024,$2/1024}')
else
  memoryusage=""
fi
{{- else }}
memoryusage=""
{{- end }}
{{- end }}
if [[ ${status} -eq 0 ]]; then
  if [[ -f /tmp/geoserver_failuretimes ]]; then
    #The file "failuretimes" exists, remove  it
    rm -f /tmp/geoserver_failuretimes
    {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is back to online again. ${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
    {{- end }}
  {{- if ge $log_level ((get $log_levels "DEBUG") | int) }}
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is online. ${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
  {{- else }}
  elif [[ "$memoryusage" != "" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is online. ${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
  {{- end }}
  fi
  exit 0
fi
{{- if eq ($livenessProbe.failureThreshold | default 2 | int) 1 }}
  {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is offline, restart. ${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
  {{- end }}
  exit ${status}
{{- else }}
if [[ -f /tmp/geoserver_failuretimes ]]; then
  failureTimes=$(cat /tmp/geoserver_failuretimes)
  failureTimes=$((${failureTimes} + 1))
else
  failureTimes=1
fi
echo ${failureTimes} > /tmp/geoserver_failuretimes
if [[ ${failureTimes} -ge {{ $livenessProbe.failureThreshold | default 2 }} ]]; then
  #geoserver is not available 
  {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is offline on the ${failureTimes}th continous check, restart. ${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
  {{- end }}
  exit ${status}
else
  {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is offline on the ${failureTimes}th continous check, need to check again.${memoryusage}" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
  {{- end }}
  exit 0
fi
{{- end }}
{{- end }}

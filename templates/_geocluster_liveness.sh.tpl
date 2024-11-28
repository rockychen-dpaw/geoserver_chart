{{- define "geocluster.geoserver_liveness" }}#!/bin/bash
LIVENESSLOG_EXPIREDAYS={{$.Values.geoserver.livenesslogExpiredays | default 30}}
{{- $log_levels := dict "DISABLE" 0 "ERROR" 100 "WARNING" 200 "INFO" 300 "DEBUG" 400 }}
{{- $log_levelname := upper ($.Values.geoserver.livenesslog | default "DISABLE") }}
{{- if not (hasKey $log_levels $log_levelname) }}
{{- $log_levelname = "DISABLE" }}
{{- end }}
{{- $log_level := (get $log_levels $log_levelname) | int }}
{{- $livenessProbe :=  $.Values.geoserver.livenessProbe | default dict }}

{{ $.Files.Get "static/manage_livenesslog.sh"  }}

{{- if and (gt ($.Values.geoserver.replicas | default 1 | int) 1) (get $.Values.geoserver "restartPolicy") (get $.Values.geoserver.restartPolicy "restartSchedule") }}
if [[ -f ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime ]]; then
  nextRestartSeconds=$(cat ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime)
  now=$(date '+%Y-%m-%d %H:%M:%S')
  hour=$(date -d "${now}" '+%H')
  hour="${hour#0*}"
  seconds=$(date -d "${now}" '+%s')

  if [[ ${seconds} -ge ${nextRestartSeconds} ]]; then
    #need to restart
    {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is scheduled to restart at $(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')." >> ${livenesslogfile}
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
      echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : check whether it is safe to restart the geoserver." >> ${livenesslogfile}
      {{- end }}
      status=0
      {{- range $i,$index := until ($.Values.geoserver.replicas | default 1 | int) }}
      if [[ "{{ $.Release.Name}}-geocluster-{{$i}}" != "${HOSTNAME}" ]] && [[ ${status} -eq 0 ]]; then
        {{- if eq $i 0 }}
        server="{{$.Release.Name}}-geoclusteradmin"
        {{- else }}
        server="{{$.Release.Name}}-geoclusterslave{{$i}}"
        {{- end }}
        wget --tries=1 --timeout={{$.Values.geoserver.liveCheckTimeout | default 0.5 }} http://${server}:8080/geoserver/www/server/nextrestarttime -o /dev/null -O /tmp/remotegeoserver_nextrestarttime
        status=$((${status} + $?))
        if [[ $status -eq 0 ]]; then
          remoteGeoserverNextRestartTime=$(cat /tmp/remotegeoserver_nextrestarttime)
          if [[ ${remoteGeoserverNextRestartTime} -lt ${nextRestartSeconds} ]]; then
            #remote geoserver should be restarted before this geoserver
            #can't restart this geoserver now
            status=99
            {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
            echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: The remote geoserver(http://${server}:8080/geoserver) is online and its next restart time is $(date -d @${remoteGeoserverNextRestartTime} '+%Y-%m-%d %H:%M:%S') which is earlier than the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')), Can't restart." >> ${livenesslogfile}
            {{- end }}
          elif [[ ${remoteGeoserverNextRestartTime} -eq ${nextRestartSeconds} ]]; then
            index="${HOSTNAME#{{ $.Release.Name }}-geocluster-*}"
            if [[ ${index} -gt {{$i}} ]]; then
              status=99
              {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
              echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: The remote geoserver(http://${server}:8080/geoserver) is online and its next restart time is $(date -d @${remoteGeoserverNextRestartTime} '+%Y-%m-%d %H:%M:%S') which is equal with the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')), but the server index(${index}) is greater than the remote geoserver index({{$i}}), Can't restart." >> ${livenesslogfile}
              {{- end }}
            {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
            else
              echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: The remote geoserver(http://${server}:8080/geoserver) is online and its next restart time is $(date -d @${remoteGeoserverNextRestartTime} '+%Y-%m-%d %H:%M:%S') which is equal with the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')), but the server index(${index}) is less than the remote geoserver index({{$i}}), can restart before the remote geoserver." >> ${livenesslogfile}
            {{- end }}
            fi
          {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
          else
            echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : The remote geoserver(http://${server}:8080/geoserver) is online and its next restart time is $(date -d @${remoteGeoserverNextRestartTime} '+%Y-%m-%d %H:%M:%S') which is later than the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')), can restart before the remote geoserver." >> ${livenesslogfile}
          {{- end }}
          fi
        {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
        else
          echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : The remote geoserver(http://${server}:8080/geoserver) is offline(status=${status})." >> ${livenesslogfile}
        {{- end }}
        fi
      fi
      {{- end }}
      if [[ $status -eq 0 ]]; then
        #try to restart this geoserver
        {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
          {{- if gt ($.Values.geoserver.memoryMonitorInterval | default 0 | int) 0  }}
        geoserverpid=$(cat /tmp/geoserverpid)
        printf -v memoryusage "%%CPU: %s , Virtual Memory: %sMB , Physical Memory: %sMB" $(ps -o %cpu=,vsz=,rss= ${geoserverpid} | awk '{printf "%.1f %.0f %.0f",$1,$2/1024,$3/1024}')
          {{- else }}
        memoryusage=""
          {{- end }}
        echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: All remote geoservers are online and also their next restart time are later than the current geoserver's next restart time($(date -d @${nextRestartSeconds} '+%Y-%m-%d %H:%M:%S')). Try to restart the current geoserver. ${memoryusage}" >> ${livenesslogfile}
        {{- end }}

        if [[ "${memoryusage}" != "" ]]; then
          sed -i -e "s/<span id=\"monitortime\">[^<]*<\/span>/<span id=\"monitortime\">$(date '+%Y-%m-%d %H:%M:%S')<\/span>/" -e "s/<span id=\"resourceusage\">[^<]*<\/span>/<span id=\"resourceusage\">${memoryusage}<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html
        fi

        exit 1
      {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
      else
        echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : It is not safe to restart the geoserver right now" >> ${livenesslogfile}
      {{- end }}
      fi
    fi
  fi
fi
{{- end}}
starttime=$(date '+%s.%N')
wget --tries=1 --timeout={{$.Values.geoserver.liveCheckTimeout | default 0.5 }} http://127.0.0.1:8080/geoserver/www/server/starttime -o /dev/null -O /dev/null
status=$?
endtime=$(date '+%s.%N')
pingtime=$(perl -e "print (${endtime} - ${starttime}) * 1000")
if [[ ${status} -eq 0 ]]; then
    pingstatus="Succeed"
else
    pingstatus="Failed"
fi
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
{{- end }}

if [[ "${memoryusage}" != "" ]]; then
  sed -i -e "s/<span id=\"monitortime\">[^<]*<\/span>/<span id=\"monitortime\">$(date '+%Y-%m-%d %H:%M:%S')<\/span>/" -e "s/<span id=\"resourceusage\">[^<]*<\/span>/<span id=\"resourceusage\">${memoryusage}<\/span>/" -e "s/<span id=\"heartbeat\">[^<]*<\/span>/<span id=\"heartbeat\">${now}<\/span>/" -e "s/<span id=\"heartbeat_status\">[^<]*<\/span>/<span id=\"heartbeat_status\">${pingstatus}<\/span>/" -e "s/<span id=\"heartbeat_processingtime\">[^<]*<\/span>/<span id=\"heartbeat_processingtime\">${pingtime}<\/span>/" ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html
else
    sed -i -e "s/<span id=\"heartbeat\">[^<]*<\/span>/<span id=\"heartbeat\">${now}<\/span>/" -e "s/<span id=\"heartbeat_status\">[^<]*<\/span>/<span id=\"heartbeat_status\">${pingstatus}<\/span>/" -e "s/<span id=\"heartbeat_processingtime\">[^<]*<\/span>/<span id=\"heartbeat_processingtime\">${pingtime}<\/span>/" ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html
fi

if [[ ${status} -eq 0 ]]; then
  if [[ -f /tmp/geoserver_failuretimes ]]; then
    #The file "failuretimes" exists, remove  it
    rm -f /tmp/geoserver_failuretimes
    {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is back to online again. ${memoryusage} , ping: ${pingstatus} , pingtime: ${pingtime}" >> ${livenesslogfile}
    {{- end }}
  {{- if ge $log_level ((get $log_levels "DEBUG") | int) }}
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is online. ${memoryusage} , ping: ${pingstatus} , pingtime: ${pingtime}" >> ${livenesslogfile}
  {{- else }}
  elif [[ "$memoryusage" != "" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is online. ${memoryusage} , ping: ${pingstatus} , pingtime: ${pingtime}" >> ${livenesslogfile}
  {{- end }}
  fi
  exit 0
fi
{{- if eq ($livenessProbe.failureThreshold | default 2 | int) 1 }}
  {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is offline, restart. ${memoryusage} , ping: ${pingstatus} , pingtime: ${pingtime}" >> ${livenesslogfile}
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
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is offline on the ${failureTimes}th continous check, restart. ${memoryusage} , ping: ${pingstatus} , pingtime: ${pingtime}" >> ${livenesslogfile}
  {{- end }}
  exit ${status}
else
  {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness : Geoserver is offline on the ${failureTimes}th continous check, need to check again.${memoryusage} , ping: ${pingstatus} , pingtime: ${pingtime}" >> ${livenesslogfile}
  {{- end }}
  exit 0
fi
{{- end }}

{{- end }}

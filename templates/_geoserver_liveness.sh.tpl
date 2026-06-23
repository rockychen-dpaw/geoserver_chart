{{- define "geoserver.geoserver_liveness" }}#!/bin/bash
{{- $adminServerIsWorker :=  true }}
{{- if hasKey $.Values.geoserver "adminServerIsWorker" }}
  {{- $adminServerIsWorker =  $.Values.geoserver.adminServerIsWorker }}
{{- end }}


source /geoserver/bin/set_geoserverrole
geoserverpid=$(cat /tmp/geoserver/geoserverpid)

LIVENESSLOG_EXPIREDAYS={{$.Values.geoserver.livenesslogExpiredays | default 30}}
{{- $log_levels := dict "DISABLED" 0 "ERROR" 100 "WARNING" 200 "INFO" 300 "DEBUG" 400 }}
{{- $log_levelname := upper ($.Values.geoserver.livenesslog | default "DISABLED") }}
{{- if not (hasKey $log_levels $log_levelname) }}
{{- $log_levelname = "DISABLED" }}
{{- end }}
{{- $log_level := (get $log_levels $log_levelname) | int }}
{{- $livenessProbe :=  $.Values.geoserver.livenessProbe | default dict }}

{{- if ge $log_level ((get $log_levels "ERROR") | int) }}
    {{ $.Files.Get "static/manage_livenesslog.sh"  }}
{{- end }}

{{- if and (get $.Values.geoserver "restartPolicy") (get $.Values.geoserver.restartPolicy "restartSchedule") }}
#can restart if the var 'restart' which is set by the script is 1 otherwise can't restart
#check whether can restart the geoserver.the var 'canRestart' will be set to 1 if can restart, otherwise will set to 0
source /geoserver/bin/geoserver_can_restart
if [[ ${canRestart} -eq 1 ]]; then
  #check whether should restart the geoserver.the var 'restart' will be set to  1 if should restart, otherwise will set to 0
  pingtime=0
  pingstatus="N/A"
{{ $.Files.Get "static/resourceusage.sh" | indent 2 }}
  source /geoserver/bin/geoserver_restart
  if [[ ${restart} -eq 1 ]]; then
    if [[ ! -f "/tmp/geoserver/serverinfo.html" ]]; then
      #the serverinfo.html doesn't exist, recover it from backup file
      cp ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html.bak /tmp/geoserver/serverinfo.html
    fi
    exit 1
  fi
fi
{{- end}}
#don't restart. check whether geoserver is online
starttime=$(date '+%s.%N')
wget --tries=1 -nv --timeout={{$.Values.geoserver.liveCheckTimeout | default 0.5 }} http://127.0.0.1:8080/geoserver/www/server/readytime -o /dev/null -O /dev/null
status=$?
endtime=$(date '+%s.%N')
pingtime=$(perl -e "print (${endtime} - ${starttime}) * 1000")
if [[ ${status} -eq 0 ]]; then
    pingstatus="Succeed"
else
    pingstatus="Failed"
fi

#get the resource usage of geoserver
{{ $.Files.Get "static/resourceusage.sh" }}

if [[ "${resourceusage}" != "" ]]; then
  sed -i -e "s/<span id=\"monitortime\">[^<]*<\/span>/<span id=\"monitortime\">$(date '+%Y-%m-%d %H:%M:%S')<\/span>/" -e "s/<span id=\"resourceusage\">[^<]*<\/span>/<span id=\"resourceusage\">${resourceusage}<\/span>/" -e "s/<span id=\"heartbeat\">[^<]*<\/span>/<span id=\"heartbeat\">${now}<\/span>/" -e "s/<span id=\"heartbeat_status\">[^<]*<\/span>/<span id=\"heartbeat_status\">${pingstatus}<\/span>/" -e "s/<span id=\"heartbeat_processingtime\">[^<]*<\/span>/<span id=\"heartbeat_processingtime\">${pingtime}<\/span>/" /tmp/geoserver/serverinfo.html
else
    sed -i -e "s/<span id=\"heartbeat\">[^<]*<\/span>/<span id=\"heartbeat\">${now}<\/span>/" -e "s/<span id=\"heartbeat_status\">[^<]*<\/span>/<span id=\"heartbeat_status\">${pingstatus}<\/span>/" -e "s/<span id=\"heartbeat_processingtime\">[^<]*<\/span>/<span id=\"heartbeat_processingtime\">${pingtime}<\/span>/" /tmp/geoserver/serverinfo.html
fi

livenesslog=0
{{- if ge $log_level ((get $log_levels "ERROR") | int) }}
  {{- if gt ($.Values.geoserver.memoryMonitorInterval | default 0 | int) 0  }}
nexttime=$(cat /tmp/geoserver/memorymonitornexttime)
if [[ $(date '+%s') -ge ${nexttime} ]] ; then
  livenesslog=1
  echo "$((${nexttime} + {{- $.Values.geoserver.memoryMonitorInterval}}))" > /tmp/geoserver/memorymonitornexttime
elif [[ ${status} -ne 0 ]]; then
  livenesslog=1
fi
  {{- end }}
{{- end }}

if [[ ${status} -eq 0 ]]; then
  if [[ -f /tmp/geoserver_failuretimes ]]; then
    #The file "failuretimes" exists, remove  it
    rm -f /tmp/geoserver_failuretimes
    {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: Geoserver is back to online again. ${resourceusage}, ping: ${pingstatus}, pingtime: ${pingtime}" >> ${livenesslogfile}
    {{- end }}
  {{- if ge $log_level ((get $log_levels "DEBUG") | int) }}
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: Geoserver is online. ${resourceusage}, ping: ${pingstatus}, pingtime: ${pingtime}" >> ${livenesslogfile}
  {{- else }}
  elif [[ ${livenesslog} -eq 1 ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: Geoserver is online. ${resourceusage}, ping: ${pingstatus}, pingtime: ${pingtime}" >> ${livenesslogfile}
  {{- end }}
  fi
  if [[ ! -f "/tmp/geoserver/serverinfo.html" ]]; then
    #the serverinfo.html doesn't exist, recover it from backup file
    cp ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html.bak /tmp/geoserver/serverinfo.html
  fi
  exit 0
fi

{{- if eq ($livenessProbe.failureThreshold | default 2 | int) 1 }}
  {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: Geoserver is offline, restart. ${resourceusage}, ping: ${pingstatus}, pingtime: ${pingtime}" >> ${livenesslogfile}
  {{- end }}
  if [[ ! -f "/tmp/geoserver/serverinfo.html" ]]; then
    #the serverinfo.html doesn't exist, recover it from backup file
    cp ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html.bak /tmp/geoserver/serverinfo.html
  fi
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
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: Geoserver is offline on the ${failureTimes}th continous check, restart. ${resourceusage}, ping: ${pingstatus}, pingtime: ${pingtime}" >> ${livenesslogfile}
  {{- end }}
  if [[ ! -f "/tmp/geoserver/serverinfo.html" ]]; then
    #the serverinfo.html doesn't exist, recover it from backup file
    cp ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html.bak /tmp/geoserver/serverinfo.html
  fi
  exit ${status}
else
  {{- if ge $log_level ((get $log_levels "ERROR") | int) }}
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Liveness: Geoserver is offline on the ${failureTimes}th continous check, need to check again. ${resourceusage}, ping: ${pingstatus}, pingtime: ${pingtime}" >> ${livenesslogfile}
  {{- end }}
  if [[ ! -f "/tmp/geoserver/serverinfo.html" ]]; then
    #the serverinfo.html doesn't exist, recover it from backup file
    cp ${GEOSERVER_DATA_DIR}/www/server/serverinfo.html.bak /tmp/geoserver/serverinfo.html
  fi
  exit 0
fi
{{- end }}

{{- end }}

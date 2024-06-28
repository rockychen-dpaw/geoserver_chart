{{- define "geoserver.geoserver_startup" }}#!/bin/bash
wget http://127.0.0.1:8080/geoserver/web -o /tmp/geoserver_healthcheck.log -O /tmp/geoserver_healthcheck.html
status=$?

#set geoserver starttime
if [[ $status -eq 0 ]]; then
    #geoserver is ready to use
    #write the start time
    startseconds=$(cat /tmp/geoserver_starttime)
    starttime=$(date -d @${startseconds} '+%Y-%m-%d %H:%M:%S.%N %Z')

    readyseconds=$(date '+%s')
    readytime=$(date -d @${readyseconds}  '+%Y-%m-%d %H:%M:%S.%N %Z')

    startingseconds=$((${readyseconds} - ${startseconds}))
    minutes=$((${startingseconds} / 60 ))
    seconds=$((${startingseconds} % 60 ))
    if [[ ${minutes} -eq 0 ]]; then
        minutes=""
    elif [[ ${minutes} -eq 1 ]]; then
        minutes="1 minute"
    else
        minutes="${minutes} minutes"
    fi
    if [[ ${seconds} -eq 0 ]]; then
        seconds=""
    elif [[ ${seconds} -eq 1 ]]; then
        seconds="1 second"
    else
        seconds="${seconds} seconds"
    fi
    if [[ "${minutes}" == "" ]]; then
        startingtime="${seconds}"
    elif [[ "${seconds}" == "" ]]; then
        startingtime="${minutes}"
    else
        startingtime="${minutes} ${seconds}"
    fi

    sed -i "s/<span id=\"starttime\">[^<]*<\/span>/<span id=\"starttime\">${starttime}<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/starttime.html
    sed -i "s/<span id=\"readytime\">[^<]*<\/span>/<span id=\"readytime\">${readytime}<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/starttime.html
    sed -i "s/<span id=\"startingtime\">[^<]*<\/span>/<span id=\"startingtime\">${startingtime}<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/starttime.html
    echo ${readyseconds} > ${GEOSERVER_DATA_DIR}/www/server/starttime
    #write the start history
    sed -i "s/<ol>/<ol>\n<li><label>Start At:<\/label><span>${starttime}<\/span> <label>Ready At:<\/label><span>${readytime}<\/span><label>Spent:<\/label><span>${startingtime}<\/span><\/li>/g" ${GEOSERVER_DATA_DIR}/www/server/starthistory.html
    count=$(cat ${GEOSERVER_DATA_DIR}/www/server/starthistory.html | grep "<li>" | wc -l)
    if [[ $count -gt {{$.Values.geoserver.maxstarttimes | default 1000 | int}} ]]; then
        #delete starttime items
        rows=$(($count - {{$.Values.geoserver.maxstarttimes | default 1000 | int}}))
        lastrow=$(awk '/<\/ol>/{ print NR; exit }' ${GEOSERVER_DATA_DIR}/www/server/starthistory.html)
        firstrow=$((${lastrow} - ${rows}))
        lastrow=$((${lastrow} - 1))
        sed -i -e "${firstrow},${lastrow}d" ${GEOSERVER_DATA_DIR}/www/server/starthistory.html
    fi
fi

#set geoserver next restart time
{{- if and ($.Values.geoserver.clustering | default false)  (gt ($.Values.geoserver.replicas | default 1) 1) (get $.Values.geoserver "restartPolicy") (get $.Values.geoserver.restartPolicy "restartSchedule") }}
{{- $index := 0}}
{{- range $server,$config := $.Values.geoserver.restartPolicy.restartSchedule }}

#weekday is 1 - 7, 1 is Monday
declare -a {{ $server }}RestartDay
{{- $index = 0}}
  {{- range $i,$day := list "monday" "tuesday" "wednesday" "thursday" "friday" "saturday" "sunday" }}
    {{- if has $day ($.config.restartDays | default list) }}
      {{- $index = add $index 1 }}
{{ $server }}RestartDay[{{$index}}]={{add $i 1}}
    {{- end }}
  {{- end }}

declare -a {{ $server }}RestartHour
  {{- if $config.restartHours }}
    {{- $index = 0 }}
    {{- range $i,$hour := until 24 }}
      {{- if has $hour $config.restartHours }}
        {{- $index = add $index 1 }}
{{ $server }}RestartHour[{{$index}}]={{$hour}}
      {{- end }}
    {{- end }}
  {{- else }}
{{ $server }}RestartHour[0]={{2}}
  {{- end }}
{{- end }}

key="server${HOSTNAME#{{ $.Release.Name }}-geocluster-*}"
declare -n restartDays="${key}RestartDay"
declare -n restartHours="${key}RestartHour"

now=$(date '+%Y-%m-%d %H:%M:%S')
hour=$(date -d "${now}" '+%H')
today=$(date -d "${now}" '+%Y-%m-%d')

if [[ ${#restartDays[@]} -gt 0 ]]; then
  #find next restart time
  nextHour=99
  i=0
  while [[ $i -lt ${#restartHours[@]} ]]; do
    if [[ ${restartHours[${i}]} -gt ${hour} ]]; then
      #need to restart later in the same day
      nextHour=${restartHours[${i}]}
      break
    else
      i=$(($i + 1))
    fi
  done

  if [[ ${nextHour} -eq 99 ]]; then
    #can't find a restart time in the same day
    nextHour=${restartHours[0]}

    #try to find the day of next restart
    day=$(date '+%u')
    dayOffset=99
    i=0
    while [[ $i -lt ${#restartDays[@]} ]]; do
      if [[ ${restartDays[${i}]} -gt ${day} ]]; then
        dayOffset=$((${restartDays[${i}]} - ${day}))
        break
      else
        i=$(($i + 1))
      fi
    done

    if [[ ${dayOffset} -eq 99 ]]; then
      dayOffset=$((7 - ${day} + ${restartDays[0]}))
    fi

    nextRestartTime=$(date -d "${today} ${nextHour}:00:00")
    if [[ ${dayOffset} -eq 1 ]]; then
      nextRestartTime=$(date -d "${nextRestartTime}+1 day" '+%Y-%m-%d %H:%M:%S')
    else
      nextRestartTime=$(date -d "${nextRestartTime}+${dayOffset} days" '+%Y-%m-%d %H:%M:%S')
    fi

    nextRestartSeconds=$(date -d "${nextRestartTime}" '+%s')
  else
    nextRestartTime=$(date -d "${today} ${nextHour}:00:00")
    nextRestartSeconds=$(date -d "${nextRestartTime}" '+%s')
  fi
  sed -i "s/<span id=\"nextrestarttime\">[^<]*<\/span>/<span id=\"nextrestarttime\">${nextRestartTime}<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/starttime.html
  echo ${nextRestartSeconds} > ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime
else
  sed -i "s/<span id=\"nextrestarttime\">[^<]*<\/span>/<span id=\"nextrestarttime\">N\/A<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/starttime.html
  rm -rf ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime
fi
{{- else }}
sed -i "s/<span id=\"nextrestarttime\">[^<]*<\/span>/<span id=\"nextrestarttime\">N\/A<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/starttime.html
rm -rf ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime
{{- end }}


exit $status
{{- end }}


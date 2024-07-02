{{- define "geoserver.geoserver_startup" }}#!/bin/bash
wget --tries=1 --timeout=0.5 http://127.0.0.1:8080/geoserver/web -o /dev/null -O /dev/null
status=$?

#set geoserver starttime
if [[ $status -eq 0 ]]; then
    #geoserver is ready to use

    #set geoserver next restart time
    {{- if and ($.Values.geoserver.clustering | default false)  (gt ($.Values.geoserver.replicas | default 1 | int) 1) (get $.Values.geoserver "restartPolicy") (get $.Values.geoserver.restartPolicy "restartSchedule") }}
    {{- $index := 0}}
    {{- $found := 0}}
    {{- range $server,$config := $.Values.geoserver.restartPolicy.restartSchedule }}
    
    #weekday is 1 - 7, 1 is Monday
    declare -a {{ $server }}RestartDay
    {{- $index = 0}}
      {{- range $i,$day := list "monday" "tuesday" "wednesday" "thursday" "friday" "saturday" "sunday" }}
        {{- $found = 0 }}
        {{- range $j,$d := ($config.restartDays | default list) }}
          {{- if or (eq $day (lower $d)) (eq (substr 0 3 $day) (lower $d)) }}
            {{- $found = 1 }}
          {{- end }}
        {{- end }}
    
        {{- if eq $found 1 }}
    {{ $server }}RestartDay[{{$index}}]={{add $i 1}}
          {{- $index = add $index 1 }}
        {{- end }}
      {{- end }}
    
    declare -a {{ $server }}RestartTimes
      {{- if $config.restartTimes }}
        {{- range $i,$time := ($config.restartTimes | sortAlpha) }}
    {{ $server }}RestartTimes[{{$i}}]={{$time | quote}}
        {{- end }}
      {{- else }}
    {{ $server }}RestartTimes[0]={{2}}
      {{- end }}
    {{- end }}
    
    key="server${HOSTNAME#{{ $.Release.Name }}-geocluster-*}"
    declare -n restartDays="${key}RestartDay"
    declare -n restartTimes="${key}RestartTimes"
    
    now=$(date '+%Y-%m-%d %H:%M:%S')
    today=$(date -d "${now}" '+%Y-%m-%d')
    seconds=$(date -d "${now}" '+%s')
    
    if [[ ${#restartDays[@]} -gt 0 ]]; then
      #find next restart time
      nextRestartTime=""
      startTime=0
      i=0
      while [[ $i -lt ${#restartTimes[@]} ]]; do
        startTime=$(date -d "${today} ${restartTimes[${i}]}" "+%s" )
        if [[ ${startTime} -gt ${seconds} ]]; then
          #need to restart later in the same day
          nextRestartTime="${today} ${restartTimes[${i}]}"
          break
        else
          i=$(($i + 1))
        fi
      done
    
      if [[ "${nextRestartTime}" == "" ]]; then
        #can't find a restart time in the same day
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
    
        nextRestartTime=$(date -d "${today} ${restartTimes[0]}")
        if [[ ${dayOffset} -eq 1 ]]; then
          nextRestartTime=$(date -d "${nextRestartTime}+1 day" '+%Y-%m-%d %H:%M:%S')
        else
          nextRestartTime=$(date -d "${nextRestartTime}+${dayOffset} days" '+%Y-%m-%d %H:%M:%S')
        fi
      fi
      nextRestartSeconds=$(date -d "${nextRestartTime}" '+%s')
      sed -i "s/<span id=\"nextrestarttime\">[^<]*<\/span>/<span id=\"nextrestarttime\">${nextRestartTime}<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/starttime.html
      echo ${nextRestartSeconds} > ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime
      {{- if $.Values.geoserver.healthchecklog | default false }}
      echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Startup : next restarttime is ${nextRestartTime}" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
      {{- end }}
    else
      sed -i "s/<span id=\"nextrestarttime\">[^<]*<\/span>/<span id=\"nextrestarttime\">N\/A<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/starttime.html
      nextRestartTime="N/A"
      rm -rf ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime
      {{- if $.Values.geoserver.healthchecklog | default false }}
      echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Startup : next restarttime is N/A" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
      {{- end }}
    fi
    {{- else }}
    sed -i "s/<span id=\"nextrestarttime\">[^<]*<\/span>/<span id=\"nextrestarttime\">N\/A<\/span>/g" ${GEOSERVER_DATA_DIR}/www/server/starttime.html
    rm -rf ${GEOSERVER_DATA_DIR}/www/server/nextrestarttime
    nextRestartTime="N/A"
    {{- if $.Values.geoserver.healthchecklog | default false }}
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Startup : next restarttime is N/A" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
    {{- end }}
    {{- end }}

    #write the start time
    startseconds=$(cat /tmp/geoserver_starttime)
    starttime=$(date -d @${startseconds} '+%Y-%m-%d %H:%M:%S %Z')

    readyseconds=$(date '+%s')
    readytime=$(date -d @${readyseconds}  '+%Y-%m-%d %H:%M:%S %Z')

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
    sed -i "s/<ol>/<ol>\n<li><label>Start At:<\/label><span>${starttime}<\/span><label>Ready At:<\/label><span>${readytime}<\/span><label>Scheduled Restart At:<\/label><span>${nextRestartTime}<\/span><label>Starting Time:<\/label><span>${startingtime}<\/span><\/span><\/li>/g" ${GEOSERVER_DATA_DIR}/www/server/starthistory.html
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

{{- if $.Values.geoserver.healthchecklog | default false }}
if [[ ${status} -eq 0 ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Startup : Geoserver is ready" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
else
  echo "$(date '+%Y-%m-%d %H:%M:%S.%N') Startup : Geoserver is not ready" >> ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
fi
{{- end }}
exit $status
{{- end }}


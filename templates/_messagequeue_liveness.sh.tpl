{{- define "messagequeue.mq_liveness" }}#!/bin/bash
#if [[ -f /tmp/nextcleantime ]]; then
#    cleantime=$(cat /tmp/nextcleantime)
#else
#    cleantime=0
#fi
#
#if [[ ${cleantime} -lt $(date '+%s') ]]; then
#    #clean outdated log file
#    find ${ACTIVEMQ_HOME}/data/kahadb -name "*.log" -mtime +4 -exec rm -f {} \;
#
#    #next clean time
#    echo "$(date -d '+1 day' '+%s')" > /tmp/nextcleantime
#
#fi

#check whether messagequeue is ready
wget --tries=1 --timeout={{$.Values.messagequeue.livenessProbe.timeoutSeconds | default 0.5 }} http://127.0.0.1:8161/index.html -o /dev/null -O /dev/null
status=$?
exit ${status}
{{- end }}

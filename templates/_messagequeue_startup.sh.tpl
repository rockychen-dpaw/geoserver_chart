{{- define "messagequeue.mq_startup" }}#!/bin/bash
#check whether messagequeue is ready
wget --tries=1 --user=${ACTIVEMQ_WEB_USER} --password=${ACTIVEMQ_WEB_PASSWORD} --timeout={{$.Values.messagequeue.livenessProbe.timeoutSeconds | default 0.5 }} http://127.0.0.1:8161/index.html -o /dev/null -O /dev/null
status=$?
exit ${status}
{{- end }}

{{- define "messagequeue.init_mq" }}#!/bin/bash
{{- if hasKey $.Values "messagequeue" }}

status=0

groupadd -r messagequeue -g {{ $.Values.messagequeue.groupid }}
status=$((${status} + $?))
useradd -l -M  -u {{ $.Values.messagequeue.userid}} --gid {{ $.Values.messagequeue.groupid }} -s /bin/bash -G messagequeue messagequeue
status=$((${status} + $?))

cp /etc/passwd /shared-data
status=$((${status} + $?))
cp /etc/group /shared-data
status=$((${status} + $?))
cp /etc/shadow /shared-data
status=$((${status} + $?))

if [[ -d /shared-data/conf ]]; then
    rm -rf /shared-data/conf/*
else
    mkdir /shared-data/conf
fi
status=$((${status} + $?))

cp -rf ${ACTIVEMQ_CONF}/*  /shared-data/conf
status=$((${status} + $?))

cp -rfH /messagequeue/config-files/* /shared-data/conf
status=$((${status} + $?))

chown -R messagequeue:messagequeue /shared-data/conf
status=$((${status} + $?))

chown -R messagequeue:messagequeue ${ACTIVEMQ_HOME}/data
status=$((${status} + $?))

chown -R messagequeue:messagequeue ${ACTIVEMQ_HOME}/tmp
status=$((${status} + $?))

if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize messagequeue
    exit ${status}"
fi
echo "Succeed to initialize messagequeue"
exit 0

{{- end }}
{{- end }}


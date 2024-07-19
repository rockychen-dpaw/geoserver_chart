{{- define "geocluster.start_geoserver" }}#!/bin/bash
echo "Check whether the cluster volume has been mounted successfully"
if [[ "${GEOWEBCACHE_CACHE_DIR}" == "" ]];then
    export GEOWEBCACHE_CACHE_DIR=${GEOSERVER_DATA_DIR}/gwc
fi

if [[ -f ${GEOSERVER_DATA_DIR}/cluster/config_data_volume ]]; then
    echo "Failed to mount the geoserver's cluster folder"
    exit 1
fi

if [[ -f ${GEOSERVER_DATA_DIR}/monitoring/config_data_volume ]]; then
    echo "Failed to mount the geoserver's monitoring folder"
    exit 1
fi

if [[ -f ${GEOSERVER_DATA_DIR}/www/server/config_data_volume ]]; then
    echo "Failed to mount the geoserver's monitoring folder"
    exit 1
fi

if [[ "${GEOWEBCACHE_CACHE_DIR}" == "${GEOSERVER_DATA_DIR}/"* ]]; then
    if [[ -f ${GEOWEBCACHE_CACHE_DIR}/config_data_volume ]]; then
        echo "Failed to mount the geoserver's gwc folder"
        exit 1
    fi
fi

echo "Copy extra config files"

status=0

cp ${GEOSERVER_HOME}/settings/starttime.html ${GEOSERVER_DATA_DIR}/www/server
status=$((${status} + $?))

echo "$(date '+%s')" > /tmp/geoserver_starttime
status=$((${status} + $?))

if [[ ! -f "${GEOSERVER_DATA_DIR}/www/server/starthistory.html" ]]; then
    cp ${GEOSERVER_HOME}/settings/starthistory.html ${GEOSERVER_DATA_DIR}/www/server
    status=$((${status} + $?))
fi

if [[ ! -d "${EXTRA_CONFIG_DIR}" ]];then
  mkdir -p "${EXTRA_CONFIG_DIR}"
  status=$((${status} + $?))
fi

cp -f ${GEOSERVER_HOME}/settings/broker.xml ${EXTRA_CONFIG_DIR}/broker.xml
status=$((${status} + $?))

if [[ "${HOSTNAME}" == "{{ $.Release.Name }}-geocluster-0" ]]; then
  echo "Copy the cluster.properties for geocluster admin to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/admin.cluster.properties ${EXTRA_CONFIG_DIR}/cluster.properties
else
  echo "Copy the cluster.properties for geocluster slave to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/slave.cluster.properties ${EXTRA_CONFIG_DIR}/cluster.properties
fi
status=$((${status} + $?))

echo "Copy the customzied geoserver config files from ${GEOSERVER_HOME}/settings to ${GEOWEBCACHE_CACHE_DIR}"
if [[ ! -d "${GEOWEBCACHE_CACHE_DIR}" ]]; then
  mkdir -p "${GEOWEBCACHE_CACHE_DIR}"
  status=$((${status} + $?))
fi

cp ${GEOSERVER_HOME}/settings/geowebcache.xml ${GEOWEBCACHE_CACHE_DIR}
status=$((${status} + $?))

{{- if $.Values.geoserver.healthchecklog | default false }}
#manage  healthcheck log
if [[ -f ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log ]]; then
  echo "Manage the length of the healthcheck log"
  rows=$(cat ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log | wc -l )
  if [[ ${rows} -gt 10000 ]]; then
    firstrow=1
    lastrow=$((${rows} - 10000))
    sed -i -e "${firstrow},${lastrow}d" ${GEOSERVER_DATA_DIR}/www/server/healthcheck.log
    status=$((${status} + $?))
  fi
fi 
{{- end }}

if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize geoserver"
    exit ${status}
fi

if [[ "${HOSTNAME}" == "{{ $.Release.Name }}-geocluster-0" ]]; then
  export GEOSERVER_CSRF_WHITELIST={{ (printf "%s,%s" ($.Values.geoserver.domain | default (printf "%s.dbca.wa.gov.au" $.Release.Name)) ($.Values.geoserver.adminDomain | default (printf "%sadmin.dbca.wa.gov.au" $.Release.Name ))) | quote }}
else
  slaveindex=${HOSTNAME#*{{- printf "%s-geocluster-" $.Release.Name }}}
  export GEOSERVER_CSRF_WHITELIST="$(printf {{ (printf "%s,%s" ($.Values.geoserver.domain | default (printf "%s.dbca.wa.gov.au" $.Release.Name )) ($.Values.geoserver.slaveDomain | default "kmislave%d-uat.dbca.wa.gov.au")) | quote }} ${slaveindex})"
fi
echo "GEOSERVER_CSRF_WHITELIST=${GEOSERVER_CSRF_WHITELIST}"
echo "Begin to start geoserver"
/scripts/entrypoint.sh
exit $?
{{- end }}


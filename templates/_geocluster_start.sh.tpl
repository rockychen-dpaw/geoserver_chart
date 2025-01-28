{{- define "geocluster.start_geoserver" }}#!/bin/bash
source /geoserver/bin/set_geoclusterrole

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

status=0

#setup index page
/geoserver/bin/setup_index_page
status=$((${status} + $?))

echo "Copy extra config files"
cp ${GEOSERVER_HOME}/settings/serverinfo.html ${GEOSERVER_DATA_DIR}/www/server
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

if [[ "${GEOCLUSTER_ROLE}" == "admin" ]]; then
  echo "Copy the cluster.properties for geocluster admin to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/admin.cluster.properties ${EXTRA_CONFIG_DIR}/cluster.properties
else
  echo "Copy the cluster.properties for geocluster slave to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/slave.cluster.properties ${EXTRA_CONFIG_DIR}/cluster.properties
fi
status=$((${status} + $?))

{{- if gt (len ($.Values.geoserver.customsettings | default list)) 0  }}
echo "Copy the custom settings to geoserver data dir"
cp -rfL /geoserver/customsettings/* ${GEOSERVER_DATA_DIR}
status=$((${status} + $?))
{{- end }}

if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize geoserver"
    exit ${status}
fi

if [[ "${GEOCLUSTER_ROLE}" == "admin" ]]; then
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


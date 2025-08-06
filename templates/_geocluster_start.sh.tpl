{{- define "geocluster.start_geoserver" }}#!/bin/bash
source /geoserver/bin/set_geoclusterrole

echo "Check whether the cluster volume has been mounted successfully"
if [[ "${GEOWEBCACHE_CACHE_DIR}" == "" ]];then
    export GEOWEBCACHE_CACHE_DIR=${GEOSERVER_DATA_DIR}/gwc
fi

{{- if contains "hz-cluster-plugin" $.Values.geoserver.configmaps.settings.COMMUNITY_EXTENSIONS }}
if [[ -f ${GEOSERVER_DATA_DIR}/logs/logging/geoserver_catalog_volume ]]; then
    echo "Failed to mount the geoserver's logging folder"
    exit 1
fi
{{- end }}

if [[ -f ${GEOSERVER_DATA_DIR}/cluster/geoserver_catalog_volume ]]; then
    echo "Failed to mount the geoserver's cluster folder"
    exit 1
fi

if [[ -f ${GEOSERVER_DATA_DIR}/monitoring/geoserver_catalog_volume ]]; then
    echo "Failed to mount the geoserver's monitoring folder"
    exit 1
fi

if [[ -f ${GEOSERVER_DATA_DIR}/www/server/geoserver_catalog_volume ]]; then
    echo "Failed to mount the geoserver's monitoring folder"
    exit 1
fi

if [[ "${GEOWEBCACHE_CACHE_DIR}" == "${GEOSERVER_DATA_DIR}/"* ]]; then
    if [[ -f ${GEOWEBCACHE_CACHE_DIR}/geoserver_catalog_volume ]]; then
        echo "Failed to mount the geoserver's gwc folder"
        exit 1
    fi
fi

status=0

if [[  ${DB_BACKEND} =~ [Pp][Oo][Ss][Tt][Gg][Rr][Ee][Ss] ]]; then
    #regenerate the diskquote jdbc xml
    rm -f ${GEOSERVER_DATA_DIR}/gwc/geowebcache-diskquota-jdbc.xml
else
    #remove the diskquota.lck
    rm -f ${GEOSERVER_DATA_DIR}/gwc/diskquota_page_store_hsql/diskquota.lck
fi

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

{{- if contains "hz-cluster-plugin" $.Values.geoserver.configmaps.settings.COMMUNITY_EXTENSIONS }}
  echo "Copy the hazelcast_cluster.properties to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/hazelcast_cluster.properties ${EXTRA_CONFIG_DIR}/
  status=$((${status} + $?))
  echo "Copy the hazelcast.xml to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/hazelcast.xml ${EXTRA_CONFIG_DIR}/
  status=$((${status} + $?))
{{- end }}

{{- if contains "jms-cluster-plugin" $.Values.geoserver.configmaps.settings.COMMUNITY_EXTENSIONS }}
#jms cluster is used
cp -f ${GEOSERVER_HOME}/settings/broker.xml ${EXTRA_CONFIG_DIR}/broker.xml
status=$((${status} + $?))

if [[ "${GEOCLUSTER_ROLE}" == "slave" ]]; then
  echo "Copy the cluster.properties for geocluster slave to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/slave.cluster.properties ${EXTRA_CONFIG_DIR}/cluster.properties
else
  echo "Copy the cluster.properties for geocluster admin to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/admin.cluster.properties ${EXTRA_CONFIG_DIR}/cluster.properties
fi
status=$((${status} + $?))
{{- end }}

{{- if gt (len ($.Values.geoserver.customsettings | default list)) 0  }}
echo "Copy the custom settings to geoserver data dir"
cp -rfL /geoserver/customsettings/* ${GEOSERVER_DATA_DIR}
status=$((${status} + $?))
{{- end }}

if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize geoserver"
    exit ${status}
fi

if [[ "${GEOCLUSTER_ROLE}" == "slave" ]]; then
  slaveindex=${HOSTNAME#*{{- printf "%s-geocluster-" $.Release.Name }}}
  export GEOSERVER_CSRF_WHITELIST="$(printf {{ (printf "%s,%s" ($.Values.geoserver.domain | default (printf "%s.dbca.wa.gov.au" $.Release.Name )) ($.Values.geoserver.slaveDomain | default "kmislave%d-uat.dbca.wa.gov.au")) | quote }} ${slaveindex})"
else
  export GEOSERVER_CSRF_WHITELIST={{ (printf "%s,%s" ($.Values.geoserver.domain | default (printf "%s.dbca.wa.gov.au" $.Release.Name)) ($.Values.geoserver.adminDomain | default (printf "%sadmin.dbca.wa.gov.au" $.Release.Name ))) | quote }}
fi

echo "GEOSERVER_CSRF_WHITELIST=${GEOSERVER_CSRF_WHITELIST}"
echo "Begin to start geoserver"
/scripts/entrypoint.sh
exit $?
{{- end }}


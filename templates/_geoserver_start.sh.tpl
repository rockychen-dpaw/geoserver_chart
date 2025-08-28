{{- define "geoserver.start_geoserver" }}#!/bin/bash
source /geoserver/bin/set_geoserverrole

if [[ "${GEOWEBCACHE_CACHE_DIR}" == "" ]];then
    export GEOWEBCACHE_CACHE_DIR=${GEOSERVER_DATA_DIR}/gwc
fi
status=0
{{- if and $.Values.geoserver ($.Values.geoserver.clustering | default false) }}
  {{- if and $.Values.geoserver.configmaps $.Values.geoserver.configmaps.settings (contains "hz-cluster-plugin" $.Values.geoserver.configmaps.settings.COMMUNITY_EXTENSIONS) }}
echo "Check whether the volume 'logging' has been mounted successfully"
if [[ -f ${GEOSERVER_DATA_DIR}/logs/logging/geoserver_catalog_volume ]]; then
    echo "Failed to mount the geoserver's logging folder"
    status=$((${status} + 1))
fi
  {{- end }}

echo "Check whether the volume 'cluster' has been mounted successfully"
if [[ -f ${GEOSERVER_DATA_DIR}/cluster/geoserver_catalog_volume ]]; then
    echo "Failed to mount the geoserver's cluster folder"
    status=$((${status} + 1))
fi
{{- else }}
echo "Check whether the volume 'logging' has been mounted successfully"
if [[ -f ${GEOSERVER_DATA_DIR}/logs/logging/geoserver_catalog_volume ]]; then
    echo "Failed to mount the geoserver's logging folder"
    status=$((${status} + 1))
fi
{{- end }}

echo "Check whether the volume 'monitoring' has been mounted successfully"
if [[ -f ${GEOSERVER_DATA_DIR}/monitoring/geoserver_catalog_volume ]]; then
    echo "Failed to mount the geoserver's monitoring folder"
    status=$((${status} + 1))
fi

echo "Check whether the volume 'www/server' has been mounted successfully"
if [[ -f ${GEOSERVER_DATA_DIR}/www/server/geoserver_catalog_volume ]]; then
    echo "Failed to mount the geoserver's www/server folder"
    status=$((${status} + 1))
fi

echo "Check whether the volume 'gwc' has been mounted successfully"
if [[ "${GEOWEBCACHE_CACHE_DIR}" == "${GEOSERVER_DATA_DIR}/"* ]]; then
    if [[ -f ${GEOWEBCACHE_CACHE_DIR}/geoserver_catalog_volume ]]; then
        echo "Failed to mount the geoserver's gwc folder"
        status=$((${status} + 1))
    fi
fi

echo "Try to remove the diskquota file ${GEOSERVER_DATA_DIR}/gwc/geowebcache-diskquota.xml if exists"
rm -f ${GEOSERVER_DATA_DIR}/gwc/geowebcache-diskquota.xml
status=$((${status} + $?))

echo "Try to remove the diskquota jdbc file ${GEOSERVER_DATA_DIR}/gwc/geowebcache-diskquota-jdbc.xml if exists"
rm -f ${GEOSERVER_DATA_DIR}/gwc/geowebcache-diskquota-jdbc.xml
status=$((${status} + $?))

#remove the diskquota.lck
while [[ -f ${GEOSERVER_DATA_DIR}/gwc/diskquota_page_store_hsql/diskquota.lck ]]; do
    echo "Try to delete the lock file ${GEOSERVER_DATA_DIR}/gwc/diskquota_page_store_hsql/diskquota.lck to release the lock"
    rm -f ${GEOSERVER_DATA_DIR}/gwc/diskquota_page_store_hsql/diskquota.lck
    if [[ -f ${GEOSERVER_DATA_DIR}/gwc/diskquota_page_store_hsql/diskquota.lck ]]; then
        echo "Failed to delete the lock file ${GEOSERVER_DATA_DIR}/gwc/diskquota_page_store_hsql/diskquota.lck to release the lock, wait 1 second and try again"
        sleep 1
    else
        echo "Succeed to delete the lock file ${GEOSERVER_DATA_DIR}/gwc/diskquota_page_store_hsql/diskquota.lck to release the lock"
    fi
done

#setup index page
/geoserver/bin/setup_index_page
status=$((${status} + $?))

cp ${GEOSERVER_HOME}/settings/serverinfo.html ${GEOSERVER_DATA_DIR}/www/server
status=$((${status} + $?))

if [[ ! -f "${GEOSERVER_DATA_DIR}/www/server/starthistory.html" ]]; then
    cp ${GEOSERVER_HOME}/settings/starthistory.html ${GEOSERVER_DATA_DIR}/www/server
    status=$((${status} + $?))
fi

echo "$(date '+%s')" > /tmp/geoserver_starttime
status=$((${status} + $?))

echo "Copy extra config files"
if [[ ! -d "${EXTRA_CONFIG_DIR}" ]];then
  mkdir -p "${EXTRA_CONFIG_DIR}"
  status=$((${status} + $?))
fi


{{- if and $.Values.geoserver ($.Values.geoserver.clustering | default false) }}
  {{- if and $.Values.geoserver.configmaps $.Values.geoserver.configmaps.settings (contains "hz-cluster-plugin" $.Values.geoserver.configmaps.settings.COMMUNITY_EXTENSIONS) }}
  echo "Copy the hazelcast_cluster.properties to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/hazelcast_cluster.properties ${EXTRA_CONFIG_DIR}/
  status=$((${status} + $?))
  echo "Copy the hazelcast.xml to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/hazelcast.xml ${EXTRA_CONFIG_DIR}/
  status=$((${status} + $?))
  {{- end }}

  {{- if and $.Values.geoserver.configmaps $.Values.geoserver.configmaps.settings (contains "jms-cluster-plugin" $.Values.geoserver.configmaps.settings.COMMUNITY_EXTENSIONS) }}
#jms cluster is used
cp -f ${GEOSERVER_HOME}/settings/broker.xml ${EXTRA_CONFIG_DIR}/broker.xml
status=$((${status} + $?))

if [[ "${GEOSERVER_ROLE}" == "slave" ]]; then
  echo "Copy the cluster.properties for geocluster slave to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/slave.cluster.properties ${EXTRA_CONFIG_DIR}/cluster.properties
else
  echo "Copy the cluster.properties for geocluster admin to ${EXTRA_CONFIG_DIR}"
  cp -f ${GEOSERVER_HOME}/settings/admin.cluster.properties ${EXTRA_CONFIG_DIR}/cluster.properties
fi
status=$((${status} + $?))
  {{- end }}

{{- end }}

echo "Copy geowebcache-diskquota.xml to ${EXTRA_CONFIG_DIR}"
cp -f ${GEOSERVER_HOME}/settings/geowebcache-diskquota.xml ${EXTRA_CONFIG_DIR}/
status=$((${status} + $?))

echo "Copy geowebcache-diskquota-jdbc.xml to ${EXTRA_CONFIG_DIR}"
cp -f ${GEOSERVER_HOME}/settings/geowebcache-diskquota-jdbc.xml ${EXTRA_CONFIG_DIR}/
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

{{- if and $.Values.geoserver ($.Values.geoserver.clustering | default false) }}
if [[ "${GEOSERVER_ROLE}" == "slave" ]]; then
  slaveindex=${HOSTNAME#*{{- printf "%s-geocluster-" $.Release.Name }}}
  export GEOSERVER_CSRF_WHITELIST="$(printf {{ (printf "%s,%s" ($.Values.geoserver.domain | default (printf "%s.dbca.wa.gov.au" $.Release.Name )) ($.Values.geoserver.slaveDomain | default "kmislave%d-uat.dbca.wa.gov.au")) | quote }} ${slaveindex})"
else
  export GEOSERVER_CSRF_WHITELIST={{ (printf "%s,%s" ($.Values.geoserver.domain | default (printf "%s.dbca.wa.gov.au" $.Release.Name)) ($.Values.geoserver.adminDomain | default (printf "%sadmin.dbca.wa.gov.au" $.Release.Name ))) | quote }}
fi
{{- else }}
export GEOSERVER_CSRF_WHITELIST={{ (printf "%s,%s" ($.Values.geoserver.domain | default (printf "%s.dbca.wa.gov.au" $.Release.Name)) ($.Values.geoserver.adminDomain | default (printf "%sadmin.dbca.wa.gov.au" $.Release.Name ))) | quote }}
{{- end }}

echo "GEOSERVER_CSRF_WHITELIST=${GEOSERVER_CSRF_WHITELIST}"
echo "Begin to start geoserver"
/scripts/entrypoint.sh
exit $?
{{- end }}


{{- define "geoserver.init_geoserver" }}#!/bin/bash
if [[ "${GEOSERVER_DATA_DIR}" == "" ]]; then
    echo "Please configure GEOSERVER_DATA_DIR"
    exit 1
fi

if [[ ! -d ${GEOSERVER_DATA_DIR} ]]; then
    mkdir -p ${GEOSERVER_DATA_DIR}
    status=$?
    if [[ ${status} -ne 0 ]]; then
        echo "Failed to create geoserver data folder"
        exit ${status}
    fi
fi

if [[ ! -d ${GEOSERVER_DATA_DIR}/www ]]; then
    mkdir -p ${GEOSERVER_DATA_DIR}/www
    status=$?
    if [[ ${status} -ne 0 ]]; then
        echo "Failed to create folder ${GEOSERVER_DATA_DIR}/www"
        exit ${status}
    fi
fi

status=0

if [[ "${GEOWEBCACHE_CACHE_DIR}" == "" ]]; then
    export GEOWEBCACHE_CACHE_DIR=${GEOSERVER_DATA_DIR}/gwc
fi

#create a placeholder file on geoserver data dir and then use it to check whether the cluster volume are mounted successfully
{{- if and $.Values.geoserver ($.Values.geoserver.clustering | default false) }}
  {{- if and $.Values.geoserver.configmaps $.Values.geoserver.configmaps.settings (contains "hz-cluster-plugin" $.Values.geoserver.configmaps.settings.COMMUNITY_EXTENSIONS) }}
if [[ ! -d ${GEOSERVER_DATA_DIR}/logs/logging ]]; then
    mkdir -p ${GEOSERVER_DATA_DIR}/logs/logging
    status=$((${status} + $?))
fi

if [[ ! -f ${GEOSERVER_DATA_DIR}/logs/logging/geoserver_catalog_volume ]]; then
    touch ${GEOSERVER_DATA_DIR}/logs/logging/geoserver_catalog_volume
    status=$((${status} + $?))
fi
  {{- end }}


if [[ ! -d ${GEOSERVER_DATA_DIR}/cluster ]]; then
    mkdir ${GEOSERVER_DATA_DIR}/cluster
    status=$((${status} + $?))
fi

if [[ ! -f ${GEOSERVER_DATA_DIR}/cluster/geoserver_catalog_volume ]]; then
    touch ${GEOSERVER_DATA_DIR}/cluster/geoserver_catalog_volume
    status=$((${status} + $?))
fi
{{- end }}

if [[ ! -d ${GEOSERVER_DATA_DIR}/monitoring ]]; then
    mkdir ${GEOSERVER_DATA_DIR}/monitoring
    status=$((${status} + $?))
fi

if [[ ! -f ${GEOSERVER_DATA_DIR}/monitoring/geoserver_catalog_volume ]]; then
    touch ${GEOSERVER_DATA_DIR}/monitoring/geoserver_catalog_volume
    status=$((${status} + $?))
fi

if [[ ! -d ${GEOSERVER_DATA_DIR}/www/server ]]; then
    mkdir ${GEOSERVER_DATA_DIR}/www/server
    status=$((${status} + $?))
fi

if [[ ! -f ${GEOSERVER_DATA_DIR}/www/server/geoserver_catalog_volume ]]; then
    touch ${GEOSERVER_DATA_DIR}/www/server/geoserver_catalog_volume
    status=$((${status} + $?))
fi

if [[ ! -d "${GEOSERVER_DATA_DIR}/security" ]]; then
  cp -r "${CATALINA_HOME}"/security "${GEOSERVER_DATA_DIR}"
  status=$((${status} + $?))
fi

if [[ "${GEOWEBCACHE_CACHE_DIR}" == "${GEOSERVER_DATA_DIR}/"* ]]; then
    #gwc data folder is nested in data dir
    if [[ ! -d ${GEOWEBCACHE_CACHE_DIR} ]]; then
        mkdir -p ${GEOWEBCACHE_CACHE_DIR}
        status=$((${status} + $?))
    fi

    if [[ ! -f ${GEOWEBCACHE_CACHE_DIR}/geoserver_catalog_volume ]]; then
        touch ${GEOWEBCACHE_CACHE_DIR}/geoserver_catalog_volume
        status=$((${status} + $?))
    fi
fi

if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize geoserver"
    exit ${status}
fi
exit 0

{{- end }}


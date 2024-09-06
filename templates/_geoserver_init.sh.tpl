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

if [[ ! -d ${GEOSERVER_DATA_DIR}/www/server ]]; then
    mkdir -p ${GEOSERVER_DATA_DIR}/www/server
    status=$?
    if [[ ${status} -ne 0 ]]; then
        echo "Failed to create folder ${GEOSERVER_DATA_DIR}/www/server"
        exit ${status}
    fi
fi

status=0

cp -f  ${GEOSERVER_HOME}/settings/serverinfo.html ${GEOSERVER_DATA_DIR}/www/server
status=$((${status} + $?))

if [[ ! -f "${GEOSERVER_DATA_DIR}/www/server/starthistory.html" ]]; then
    cp ${GEOSERVER_HOME}/settings/starthistory.html ${GEOSERVER_DATA_DIR}/www/server
    status=$((${status} + $?))
fi

if [[ "${GEOWEBCACHE_CACHE_DIR}" == "" ]]; then
    export GEOWEBCACHE_CACHE_DIR=${GEOSERVER_DATA_DIR}/gwc
fi

if [[ ! -d "${GEOSERVER_DATA_DIR}/security" ]]; then
  cp -r "${CATALINA_HOME}"/security "${GEOSERVER_DATA_DIR}"
  status=$((${status} + $?))
fi

#setup index page
/geoserver/bin/setup_index_page
status=$((${status} + $?))

if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize geoserver"
    exit ${status}
fi
exit 0

{{- end }}


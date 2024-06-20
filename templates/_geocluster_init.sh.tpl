{{- define "geocluster.init_geoserver" }}#!/bin/bash
if [[ "${GEOSERVER_DATA_DIR}" == "" ]]; then
    echo "Please configure GEOSERVER_DATA_DIR"
    exit 1
fi

if [[ ! -d ${GEOSERVER_DATA_DIR} ]]; then
    mkdir -p ${GEOSERVER_DATA_DIR}
    status=$?
    if [[ ${status} -ne 0 ]]; then
        echo "Failed to create geoserver data folder"
        exit ${status}"
    fi
fi

status=0

if [[ "${GEOWEBCACHE_CACHE_DIR}" == "" ]]; then
    export GEOWEBCACHE_CACHE_DIR=${GEOSERVER_DATA_DIR}/gwc
fi

echo "Copy the customzied geoserver config files from '${GEOSERVER_HOME}/settings' to '${GEOSERVER_DATA_DIR}'"
cp ${GEOSERVER_HOME}/settings/gwc-gs.xml ${GEOSERVER_DATA_DIR}/
status=$((${status} + $?))
if [[ ! -d "${GEOSERVER_DATA_DIR}/security" ]]; then
  cp -r "${CATALINA_HOME}"/security "${GEOSERVER_DATA_DIR}"
  status=$((${status} + $?))
fi
if [[ ! -d "${GEOSERVER_DATA_DIR}/security/filter" ]]; then
  mkdir -p "${GEOSERVER_DATA_DIR}/security/filter"
  status=$((${status} + $?))
fi
if [[ ! -d "${GEOSERVER_DATA_DIR}/security/filter/nginx_sso" ]]; then
  mkdir -p "${GEOSERVER_DATA_DIR}/security/filter/nginx_sso"
  status=$((${status} + $?))
fi
cp ${GEOSERVER_HOME}/settings/security.filter.nginx_sso.config.xml ${GEOSERVER_DATA_DIR}/security/filter/nginx_sso/config.xml
status=$((${status} + $?))
cp ${GEOSERVER_HOME}/settings/security.config.xml ${GEOSERVER_DATA_DIR}/security/config.xml
status=$((${status} + $?))

if [[ ! -d ${GEOSERVER_DATA_DIR}/cluster ]]; then
    mkdir ${GEOSERVER_DATA_DIR}/cluster
    status=$((${status} + $?))
fi

if [[ ! -f ${GEOSERVER_DATA_DIR}/cluster/in_config_data_volume ]]; then
    touch ${GEOSERVER_DATA_DIR}/cluster/in_config_data_volume
    status=$((${status} + $?))
fi

if [[ ! -d ${GEOSERVER_DATA_DIR}/monitoring ]]; then
    mkdir ${GEOSERVER_DATA_DIR}/monitoring
    status=$((${status} + $?))
fi

if [[ ! -f ${GEOSERVER_DATA_DIR}/monitoring/in_config_data_volume ]]; then
    touch ${GEOSERVER_DATA_DIR}/monitoring/in_config_data_volume
    status=$((${status} + $?))
fi

if [[ ! -d ${GEOWEBCACHE_CACHE_DIR} ]]; then
    mkdir -p ${GEOWEBCACHE_CACHE_DIR}
    status=$((${status} + $?))
fi

if [[ ! -f ${GEOWEBCACHE_CACHE_DIR}/in_config_data_volume ]]; then
    touch ${GEOWEBCACHE_CACHE_DIR}/in_config_data_volume
    status=$((${status} + $?))
fi


if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize geoserver"
    exit ${status}"
fi
exit 0

{{- end }}


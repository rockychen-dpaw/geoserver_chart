{{- define "geoserver.init_geoserver" }}#!/bin/bash
status=0

if [[ "${GEOWEBCACHE_CACHE_DIR}" == "" ]]; then
    export GEOWEBCACHE_CACHE_DIR=${GEOSERVER_DATA_DIR}/gwc
fi

echo "Copy the customzied geoserver config files from '${GEOSERVER_HOME}/settings' to '${GEOWEBCACHE_CACHE_DIR}'"
if [[ ! -d "${GEOWEBCACHE_CACHE_DIR}" ]]; then
  mkdir -p "${GEOWEBCACHE_CACHE_DIR}"
  status=$((${status} + $?))
fi

cp ${GEOSERVER_HOME}/settings/geowebcache.xml ${GEOWEBCACHE_CACHE_DIR}
status=$((${status} + $?))

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
cp ${GEOSERVER_HOME}/settings/security.config.xml ${GEOSERVER_DATA_DIR}/security/config.xmlG
status=$((${status} + $?))

if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize geoserver
    exit ${status}"
fi
exit 0

{{- end }}


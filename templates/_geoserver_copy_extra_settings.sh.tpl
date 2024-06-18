{{- define "geoserver.geoserver_copy_extra_settings" }}#!/bin/bash
echo "Copy extra config files"

if [[ ! -d "${EXTRA_CONFIG_DIR}" ]];then
  mkdir -p "${EXTRA_CONFIG_DIR}"
fi  
cp /usr/local/geoserver/settings/* ${EXTRA_CONFIG_DIR}/

if [[ "${GEOWEBCACHE_CACHE_DIR}" == "" ]];then
    export GEOWEBCACHE_CACHE_DIR=${GEOSERVER_DATA_DIR}/gwc
fi

cp ${EXTRA_CONFIG_DIR}/gwc-gs.xml ${GEOSERVER_DATA_DIR}/

if [[ ! -d "${GEOWEBCACHE_CACHE_DIR}" ]];then
  mkdir -p "${GEOWEBCACHE_CACHE_DIR}"
fi  
cp ${EXTRA_CONFIG_DIR}/geowebcache.xml ${GEOWEBCACHE_CACHE_DIR}

if [[ ! -d "${GEOSERVER_DATA_DIR}/security" ]];then
  cp -r "${CATALINA_HOME}"/security "${GEOSERVER_DATA_DIR}"
fi
if [[ ! -d "${GEOSERVER_DATA_DIR}/security/filter" ]];then
  mkdir -p "${GEOSERVER_DATA_DIR}/security/filter"
fi
if [[ ! -d "${GEOSERVER_DATA_DIR}/security/filter/nginx_sso" ]];then
  mkdir -p "${GEOSERVER_DATA_DIR}/security/filter/nginx_sso"
fi
cp ${EXTRA_CONFIG_DIR}/security.filter.nginx_sso.config.xml ${GEOSERVER_DATA_DIR}/security/filter/nginx_sso/config.xml
cp ${EXTRA_CONFIG_DIR}/security.config.xml ${GEOSERVER_DATA_DIR}/security/config.xmlG
{{- end }}


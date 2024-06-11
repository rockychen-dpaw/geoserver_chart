{{- define "geoserver.geoserver_copy_extra_settings" }}#!/bin/bash
echo "Copy extra config files"
if [[ "${GEOWEBCACHE_CACHE_DIR}" == "" ]];then
    export GEOWEBCACHE_CACHE_DIR=${GEOSERVER_DATA_DIR}/gwc
fi

if [[ ! -d "${GEOWEBCACHE_CACHE_DIR}" ]];then
  create_dir "${GEOWEBCACHE_CACHE_DIR}"
fi  
cp ${EXTRA_CONFIG_DIR}/geowebcache.xml ${GEOWEBCACHE_CACHE_DIR}

if [[ ! -d "${GEOSERVER_DATA_DIR}/security" ]];then
  cp -r "${CATALINA_HOME}"/security "${GEOSERVER_DATA_DIR}"
fi
if [[ ! -d "${GEOSERVER_DATA_DIR}/security/filter" ]];then
  create_dir "${GEOSERVER_DATA_DIR}/security/filter"
fi
if [[ ! -d "${GEOSERVER_DATA_DIR}/security/filter/nginx_sso" ]];then
  create_dir "${GEOSERVER_DATA_DIR}/security/filter/nginx_sso"
fi
cp ${EXTRA_CONFIG_DIR}/security.filter.nginx_sso.config.xml ${GEOSERVER_DATA_DIR}/security/filter/nginx_sso/config.xml
cp ${EXTRA_CONFIG_DIR}/security.config.xml ${GEOSERVER_DATA_DIR}/security/config.xmlG
{{- end }}


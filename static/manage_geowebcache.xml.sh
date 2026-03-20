count=0
max=10
if [[ "${GEOWEBCACHE_XML_MAX_BACKUP_FILES}" == "" ]]; then
    max=10
else
    max=${GEOWEBCACHE_XML_MAX_BACKUP_FILES}
fi

for f in $(ls -r ${GEOSERVER_DATA_DIR}/gwc/geowebcache_*.bak ); do 
    ((count++))
    if [[ ${count} -gt ${max} ]]; then
        echo "Delete the geowebcache.xml backup file: ${f}."
        rm -f ${f}
    fi
done

today=$(date '+%Y-%m-%d')
now=$(date '+%Y-%m-%d %H:%M:%S')

livenessloghome="${GEOSERVER_DATA_DIR}/www/server/liveness"
livenesslogfile="${GEOSERVER_DATA_DIR}/www/server/liveness/${today}.log"
livenesslogindexfile="${GEOSERVER_DATA_DIR}/www/server/livenesslogindex.html"
if [[ ! -f ${livenesslogfile} ]]; then
    #new liveness log file
    #manage the liveness log file
    mkdir -p "${GEOSERVER_DATA_DIR}/www/server/liveness"
    touch ${livenesslogfile}
    if [[ ! -f ${livenesslogindexfile} ]]; then
        cp /geoserver/settings/livenesslogindex.html "${livenesslogindexfile}"
        chmod 775 "${livenesslogindexfile}"
    fi
    sed -i "/<ul>/a <li><a href='/geoserver/www/server/liveness/${today}.log'>${today}<\/a><\/li>" ${livenesslogindexfile}
    #manage the liveness files
    earliest_date=$(date --date="${today}-${LIVENESSLOG_EXPIREDAYS} days")
    earliest_seconds=$(date --date="${earliest_date}" "+%s")
    for d in $(ls "${livenessloghome}" ); do 
        logdate=${d%.log*}
        logdate_seconds=$(date --date="${logdate}" "+%s")
        logdate=$(date --date="${logdate}" "+%Y-%m-%d")
        if [[ ${logdate_seconds} -lt ${earliest_seconds} ]]; then
            #remove the expired monitoring file from serverinfofile
            #echo "The monitoring file(${d}.html) of auth2 server(${serviceid}) is expired"
            sed -i "/${logdate}<\/a><\/li>/d" "${livenesslogindexfile}"
            if [[ $? -eq 0 ]]; then
                rm -f "${livenessloghome}/${d}"
            fi
        else
            break
        fi
    done
fi

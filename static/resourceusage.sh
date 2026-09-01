set -o pipefail

if [[ "${geoserverpid}" == "" ]]; then
    geoserver_cpu=-1
    geoserver_vmemory=-1
    geoserver_pmemory=-1
else
    processmsg=$(ps -o %cpu=,vsz=,rss=,lstart= ${geoserverpid})
    if [[ $? -ne 0 ]]; then
        geoserver_cpu=0
        geoserver_vmemory=0
        geoserver_pmemory=0
    else
        eval $(echo ${processmsg} | awk '{printf "export geoserver_cpu=%.1f ; export geoserver_vmemory=%.0f ; export geoserver_pmemory=%.0f",$1,$2/1024,$3/1024}')
    fi
fi

startseconds=$(cat /tmp/geoserver_starttime)
geoserver_stime=$(date -d @${startseconds} '+%Y-%m-%dT%H:%M:%S')
export geoserver_stime

tilevolumemsg="$(df --output="pcent,used,size" -BG /geoserver/data/tiles  2>/dev/null | sed 1d)"
if [[ $? -ne 0 ]]; then
    tiles_pcent=0
    tiles_used=0
    tiles_size=0
else
    eval $(echo ${tilevolumemsg} | awk '{printf "export tiles_pcent=%.0f ; export tiles_used=%.0f ; export tiles_size=%.0f",$1,$2,$3}')
fi

datavolumemsg="$(df --output="pcent,used,size" -BG /geoserver/data/data  2>/dev/null | sed 1d)"
if [[ $? -ne 0 ]]; then
    data_pcent=0
    data_used=0
    data_size=0
else
    eval $(echo ${datavolumemsg} | awk '{printf "export data_pcent=%.0f ; export data_used=%.0f ; export data_size=%.0f",$1,$2,$3}')
fi

instancevolumemsg="$(df --output="pcent,used,size" -BM /geoserver/data/cluster 2>/dev/null | sed 1d)"
checkstatus=$?
if [[ ${checkstatus} -ne 0 ]]; then
    instancevolumemsg="$(df --output="pcent,used,size" -BM /geoserver/data/monitoring 2>/dev/null | sed 1d)"
    checkstatus=$?
    if [[ ${checkstatus} -ne 0 ]]; then
        instancevolumemsg="$(df --output="pcent,used,size" -BM /geoserver/data/www/server 2>/dev/null | sed 1d)"
        checkstatus=$?
        if [[ ${checkstatus} -ne 0 ]]; then
            instancevolumemsg="$(df --output="pcent,used,size" -BM /geoserver/data/logs/logging 2>/dev/null | sed 1d)"
            checkstatus=$?
        fi
    fi
fi

if [[ ${checkstatus} -ne 0 ]]; then
    instance_pcent=0
    instance_used=0
    instance_size=0
else
    eval $(echo ${instancevolumemsg} | awk '{printf "export instance_pcent=%.0f ; export instance_used=%.0f ; export instance_size=%.0f",$1,$2,$3}')
fi

resourceusage="CPU: ${geoserver_cpu}% , Virtual Memory:${geoserver_vmemory}MB , Physical Memory:${geoserver_pmemory}MB ; GWC Volume:${tiles_pcent}%(${tiles_used}G of ${tiles_size}G) ; Instance Volume:${instance_pcent}%(${instance_used}M of ${instance_size}M)"


set +o pipefail

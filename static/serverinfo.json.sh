finishtime=$(date '+%s.%N')
processtime=$(perl -e "print (${finishtime} - ${begintime}) * 1000")
if [[ ${data_size} -gt 0 ]]; then
    resourceusage="${resourceusage} ; Data Volume:${data_pcent}%(${data_used}M of ${data_size}M)"

    echo "{\"process_time\":${processtime},\"ping_time\":${pingtime},\"ping_status\":\"${pingstatus}\",\"stime\":\"${geoserver_stime}\",\"cpu\":${geoserver_cpu},\"vmemory\":${geoserver_vmemory},\"pmemory\":${geoserver_pmemory},\"volume_instance_used\":${instance_used},\"volume_instance_size\":${instance_size},\"volume_data_used\":${data_used},\"volume_data_size\":${data_size},\"volume_tiles_used\":${tiles_used},\"volume_tiles_size\":${tiles_size}}" > /tmp/geoserver/serverinfo.json
else
    echo "{\"process_time\":${processtime},\"ping_time\":${pingtime},\"ping_status\":\"${pingstatus}\",\"stime\":\"${geoserver_stime}\",\"cpu\":${geoserver_cpu},\"vmemory\":${geoserver_vmemory},\"pmemory\":${geoserver_pmemory},\"volume_instance_used\":${instance_used},\"volume_instance_size\":${instance_size},\"volume_tiles_used\":${tiles_used},\"volume_tiles_size\":${tiles_size}}" > /tmp/geoserver/serverinfo.json
fi


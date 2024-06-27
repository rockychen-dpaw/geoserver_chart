{{- define "geoserver.start_geoserver" }}#!/bin/bash
status=0

echo "$(date '+%s')" > /tmp/geoserver_starttime
status=$((${status} + $?))

if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize geoserver"
    exit ${status}
fi

echo "Begin to start geoserver"
/scripts/entrypoint.sh
exit $?
{{- end }}


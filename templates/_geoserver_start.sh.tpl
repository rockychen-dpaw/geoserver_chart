{{- define "geoserver.start_geoserver" }}#!/bin/bash
echo "Begin to start geoserver"
/scripts/entrypoint.sh
exit $?
{{- end }}


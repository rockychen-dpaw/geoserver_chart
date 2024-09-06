{{- define "geoserver.start_geoserver" }}#!/bin/bash
status=0

echo "$(date '+%s')" > /tmp/geoserver_starttime
status=$((${status} + $?))

{{- if gt (len ($.Values.geoserver.customsettings | default list)) 0  }}
echo "Copy the custom settings to geoserver data dir"
cp -rfL /geoserver/customsettings/* ${GEOSERVER_DATA_DIR}
status=$((${status} + $?))
{{- end }}

if [[ ${status} -ne 0 ]]; then
    echo "Failed to initialize geoserver"
    exit ${status}
fi

export GEOSERVER_CSRF_WHITELIST={{ (printf "%s,%s" ($.Values.geoserver.domain | default (printf "%s.dbca.wa.gov.au" $.Release.Name)) ($.Values.geoserver.adminDomain | default (printf "%sadmin.dbca.wa.gov.au" $.Release.Name ))) | quote }}
echo "Begin to start geoserver"
/scripts/entrypoint.sh
exit $?
{{- end }}


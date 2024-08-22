{{- define "geoserver.setup_index_page" }}#!/bin/bash
status=0
echo "Begin to setup the index page and reorts folder"
#prepare the index.html file and find the reportFolder
{{- if hasKey $.Values "geoserverHealthcheck" }}
    #geosever healthcheck enabled
    {{- if ($.Values.geoserver.clustering | default false) }}
         #geocluster deployment
         {{- if $.Values.geoserverHealthcheck.checkAllGeoservers | default true }}
             #healcheck enabled for all geoservers
echo "Copy /geoserver/settings/index.html as index page"
cp /geoserver/settings/index.html /geoserver/data/www/server/index.html
status=$((${status} + $?))
reportFolder="${HOSTNAME}"
         {{- else }}
             #healcheck enabled for geocluster admin server
if [[ "${HOSTNAME}" == "{{$.Release.Name}}-geocluster-0" ]]; then
    #admin server
    echo "Copy /geoserver/settings/index.html as index page"
    cp /geoserver/settings/index.html /geoserver/data/www/server/index.html
    status=$((${status} + $?))
    reportFolder="{{$.Release.Name}}-geocluster-0"
else
    #slave server
    echo "Copy /geoserver/settings/index_without_reports.html as index page"
    cp /geoserver/settings/index_without_reports.html /geoserver/data/www/server/index.html
    status=$((${status} + $?))
    exit ${status}
fi
         {{- end }}
    {{- else }}
       #geoserver deployment
echo "Copy /geoserver/settings/index.html as index page"
cp /geoserver/settings/index.html /geoserver/data/www/server/index.html
status=$((${status} + $?))
reportFolder="{{ $.Release.Name }}-geoserver"
    {{- end }}
{{- else }}
    #geosever healthcheck disabled
echo "Copy /geoserver/settings/index_without_reports.html as index page"
cp /geoserver/settings/index_without_reports.html /geoserver/data/www/server/index.html
status=$((${status} + $?))
exit ${status}
{{- end }}

#create the reports folder if not exist
if [[ -e "/geoserver/reports/${reportFolder}" ]]; then
    if [[ ! -d "/geoserver/reports/${reportFolder}" ]]; then
        rm -f "/geoserver/reports/${reportFolder}"
        status=$((${status} + $?))
    fi
fi
if [[ ! -d "/geoserver/reports/${reportFolder}" ]]; then
    echo "Create the reports folder(/geoserver/reports/${reportFolder})"
    mkdir "/geoserver/reports/${reportFolder}"
    status=$((${status} + $?))
else
    echo "The reports folder(/geoserver/reports/${reportFolder}) already exists"
fi

#create the reports.html if not exist
if [[ -e "/geoserver/reports/${reportFolder}/reports.html" ]]; then
    if [[ ! -f "/geoserver/reports/${reportFolder}" ]]; then
        rm -fdr "/geoserver/reports/${reportFolder}/reports.html"
        status=$((${status} + $?))
    fi
fi
if [[ ! -f "/geoserver/reports/${reportFolder}/reports.html" ]]; then
    echo "Create the default reports index page as reports index page"
    cp /geoserver/settings/default_reports.html "/geoserver/reports/${reportFolder}/reports.html"
    status=$((${status} + $?))
else
    echo "The reports index page(/geoserver/reports/${reportFolder}/reports.html) alreay exists"
fi

#create soft link
if [[ -e "${GEOSERVER_DATA_DIR}/www/server/reports" ]]; then
    if [[ ! -h "${GEOSERVER_DATA_DIR}/www/server/reports" ]]; then
        rm -fdr "${GEOSERVER_DATA_DIR}/www/server/reports"
        status=$((${status} + $?))
    fi
fi
if [[ ! -h "${GEOSERVER_DATA_DIR}/www/server/reports" ]]; then
    #create soft link www/server/reports 
    echo "Create the soft link(${GEOSERVER_DATA_DIR}/www/server/reports)"
    ln -s "/geoserver/reports/${reportFolder}" "${GEOSERVER_DATA_DIR}/www/server/reports"
    status=$((${status} + $?))
else
    echo "The soft link(${GEOSERVER_DATA_DIR}/www/server/reports) already exists"
fi

exit ${status}

{{- end }}


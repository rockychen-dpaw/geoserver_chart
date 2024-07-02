{{- define "geoserver.geoserver_liveness" }}#!/bin/bash
wget --tries=1 --timeout=0.5 http://127.0.0.1:8080/geoserver/web -o /dev/null -O /dev/null
exit $?
{{- end }}


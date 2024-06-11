{{- define "geoserver.geoserver_startup" }}#!/bin/bash
wget http://127.0.0.1:8080/geoserver/web 
exit $?
{{- end }}


{{- define "geoserver.geoserver_liveness" }}#!/bin/bash
wget http://127.0.0.1:8080/geoserver/web -o /tmp/geoserver_healthcheck.log -O /tmp/geoserver_healthcheck.html
exit $?
{{- end }}


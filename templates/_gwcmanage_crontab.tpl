{{- define "gwcmanage.crontab" }}
{{$.Values.gwcManage.schedule}}  cd /app && python -m geoserver_rest.gwcmanage

{{- end }}

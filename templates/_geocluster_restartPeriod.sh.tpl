{{- define "geocluster.restart_period.sh" }}#!/bin/bash
declare -a restartPeriod
  {{- if get $.Values.geoserver.restartPolicy "restartPeriod" }}
    {{- $index := 0}}
    {{- range $i,$config := $.Values.geoserver.restartPolicy.restartPeriod }}
restartPeriod[{{mul $i  2}}]={{ $config.startHour }}
restartPeriod[{{add (mul $i  2)  1}}]={{ $config.endHour }}
    {{- end }}
  {{- else }}
restartPeriod[0]=0
restartPeriod[1]=24
  {{- end }}
{{- end }}


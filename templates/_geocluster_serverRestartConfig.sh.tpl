{{- define "geocluster.server_restart_config.sh" }}#!/bin/bash
{{- $index := 0}}
{{- range $server,$config := $.Values.geoserver.restartPolicy.restartSchedule }}

#weekday is 1 - 7, 1 is Monday
declare -a {{ $server }}RestartDay
{{- $index = 0}}
  {{- range $i,$day := list "monday" "tuesday" "wednesday" "thursday" "friday" "saturday" "sunday" }}
    {{- if has $day ($.config.restartDay | default list) }}
      {{- $index = add $index 1 }}
{{ $server }}RestartDay[{{$index}}]={{add $i 1}}
    {{- end }}
  {{- end }}

declare -a {{ $server }}RestartHour
  {{- if $config.restartHour }}
    {{- $index = 0 }}
    {{- range $i,$hour := until 24 }}
      {{- if has $hour $config.restartHour }}
        {{- $index = add $index 1 }}
{{ $server }}RestartHour[{{$index}}]={{$hour}}
      {{- end }}
    {{- end }}
  {{- else }}
{{ $server }}RestartHour[0]={{2}}
  {{- end }}
{{- end }}

key="server${HOSTNAME#{{ $.Release.Name }}-geocluster-*}"
declare -n restartDay="${key}RestartDay"
declare -n restartHour="${key}RestartHour"

{{- end }}


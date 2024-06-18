{{- define "postgis.init_postgis" }}#!/bin/bash
{{- if hasKey $.Values "postgis" }}
{{- range $name,$config := $.Values.postgis.volumes.pvcs }}
{{- range $i,$mount := $config.mounts }}
echo "Change the ownership and permission of the path '{{ $mount.mountPath }}'"
chown -R postgres:postgres {{ $mount.mountPath }}
status=$?
if [[ ${status} -ne 0 ]]; then
    echo "Failed to change the ownership of the path '{{ $mount.mountPath }}'"
    exit ${status}
fi
chmod -R 700 {{ $mount.mountPath }}
status=$?
if [[ ${status} -ne 0 ]]; then
    echo "Failed to change the permission of the path '{{ $mount.mountPath }}'"
    exit ${status}
fi
{{- end }}
{{- end }}
exit 0
{{- end }}
{{- end }}


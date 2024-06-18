{{- define "borgslave.start_sync" }}#!/bin/bash
mkdir ~/.ssh
cp /borgslave/.ssh/known_hosts ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts

/app/start_sync.sh

exit $?

{{- end }}


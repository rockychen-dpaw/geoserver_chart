#!/bin/bash

if [[ "$1" == "uninstall" ]];then
    helm $@
    exit $?
fi
helm_dir="${@: -1}"
set -- "${@:1:$(($#-1))}"

#copy all files to /tmp/_helm_deploy
if [[ -e /tmp/_helm_deploy ]];then
    rm -rf /tmp/_helm_deploy
fi

mkdir /tmp/_helm_deploy

cp -rf ${helm_dir}/Chart.yaml /tmp/_helm_deploy
cp -rf ${helm_dir}/conf /tmp/_helm_deploy
cp -rf ${helm_dir}/static /tmp/_helm_deploy
cp -rf ${helm_dir}/templates /tmp/_helm_deploy
cp -rf ${helm_dir}/values*.yaml /tmp/_helm_deploy

echo "helm $@ /tmp/_helm_deploy"
helm $@ /tmp/_helm_deploy



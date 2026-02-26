#!/bin/bash
isuat=$(kubectl config get-contexts | grep  -E "\*\s+az-aks-oim03" | wc -l)
if [[ ${isuat} -eq 1 ]]; then
    echo "Kubectl is connected to az-aks-oim03, begin to deploy kb in uat env"
else
    echo "Kubectl is not connected to az-aks-oim03, can't deploy kb in uat env"
    exit 1
fi

./deploy.sh upgrade --values values-geocluster-kb-uat.yaml -n kmi kb-uat ./

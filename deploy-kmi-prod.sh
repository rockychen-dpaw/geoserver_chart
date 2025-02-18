#!/bin/bash
isprod=$(kubectl config get-contexts | grep  -E "\*\s+az-aks-prod01" | wc -l)
if [[ ${isprod} -eq 1 ]]; then
    echo "Kubectl is connected to az-aks-prod01, begin to deploy kmi in prod env"
else
    echo "Kubectl is not connected to az-aks-prod01, can't deploy kmi in prod env"
    exit 1
fi

./deploy.sh  upgrade --values values-geocluster-kmi-prod.yaml -n kmi kmi ./

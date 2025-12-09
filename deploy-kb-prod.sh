#!/bin/bash
isuat=$(kubectl config get-contexts | grep  -E "\*\s+az-aks-prod01" | wc -l)
if [[ ${isuat} -eq 1 ]]; then
    echo "Kubectl is connected to az-aks-prod01, begin to deploy kb in prod env"
else
    echo "Kubectl is not connected to az-aks-prod01, can't deploy kb in prod env"
    exit 1
fi

./deploy.sh upgrade --values values-geocluster-kb-prod.yaml -n kb kb1 ./

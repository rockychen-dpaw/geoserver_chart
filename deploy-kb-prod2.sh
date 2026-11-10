#!/bin/bash
isuat=$(kubectl config get-contexts | grep  -E "\*\s+aks-coe-prod-02" | wc -l)
if [[ ${isuat} -eq 1 ]]; then
    echo "Kubectl is connected to aks-coe-prod-02, begin to deploy kb2 in prod env"
else
    echo "Kubectl is not connected to aks-coe-prod-02, can't deploy kb2 in prod env"
    exit 1
fi

./deploy.sh upgrade --values values-geocluster-kb-prod2.yaml -n kb kb2 ./

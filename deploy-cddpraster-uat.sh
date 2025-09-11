#!/bin/bash
isuat=$(kubectl config get-contexts | grep  -E "\*\s+az-aks-oim03" | wc -l)
if [[ ${isuat} -eq 1 ]]; then
    echo "Kubectl is connected to az-aks-oim03, begin to deploy cddp raster in uat env"
else
    echo "Kubectl is not connected to az-aks-oim03, can't deploy cddp raster in uat env"
    exit 1
fi

./deploy.sh  upgrade --values values-geoserver-cddpraster-uat.yaml -n kmi cddpraster-uat ./

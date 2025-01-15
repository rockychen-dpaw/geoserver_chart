# Geoserver cluster Helm chart (DBCA)

This is a custom Helm chart to deploy Geoserver in a clustered arrangement on a Kubernetes cluster.

## Deployment

1. Decrypt the required values file, e.g. `./decrypt.sh values-geocluster-kmi-uat.yaml`
1. Deploy the chart, e.g. `helm upgrade -n kmi kmi --values values-geocluster-kmi-uat.yaml --dry-run ./`

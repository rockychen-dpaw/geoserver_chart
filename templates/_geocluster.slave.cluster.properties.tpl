{{- define "geoserver.slave.cluster.properties" }}
CLUSTER_CONFIG_DIR=${CLUSTER_CONFIG_DIR}
instanceName=${INSTANCE_STRING}
durable=${CLUSTER_DURABILITY}
brokerURL=failover:(${BROKER_URL})
embeddedBroker=${EMBEDDED_BROKER}
connection.retry=${CLUSTER_CONNECTION_RETRY_COUNT}
xbeanURL=./broker.xml
embeddedBrokerProperties=embedded-broker.properties
topicName=VirtualTopic.{{ $.Release.Name }}-geocluster
connection=enabled
connection.maxwait=${CLUSTER_CONNECTION_MAX_WAIT}
group={{ $.Release.Name }}-geocluster
readOnly=enabled
toggleMaster=false
toggleSlave=true
{{- end}}

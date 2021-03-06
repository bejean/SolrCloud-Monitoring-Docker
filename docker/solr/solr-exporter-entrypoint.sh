#!/bin/sh

echo "SOLR_EXPORTER_METRIC_GROUPS = $SOLR_EXPORTER_METRIC_GROUPS"
if [ ! "x$SOLR_EXPORTER_METRIC_GROUPS" == "xall" ] && [ ! "x$SOLR_EXPORTER_METRIC_GROUPS" == "x" ]; then
	echo "Updating solr-exporter-config.xml"
	sed -i "/name=\"group\"/c\<str name=\"group\">${SOLR_EXPORTER_METRIC_GROUPS}</str>" /opt/solr/contrib/prometheus-exporter/conf/solr-exporter-config.xml
fi
echo "Starting Solr exporter"
if [ ! -z "$ZK_HOSTS" ]
then
	/opt/solr/contrib/prometheus-exporter/bin/solr-exporter -p 9854 -z ${ZK_HOSTS}${ZK_CHROOT} -f /opt/solr/contrib/prometheus-exporter/conf/solr-exporter-config.xml -n 2
else
	/opt/solr/contrib/prometheus-exporter/bin/solr-exporter -p 9854 -f /opt/solr/contrib/prometheus-exporter/conf/solr-exporter-config.xml -n 2
fi
#!/bin/sh
sed -i '/name="group"/c\<str name="group">jvm,node</str>' /opt/solr/contrib/prometheus-exporter/conf/solr-exporter-config.xml
/opt/solr/contrib/prometheus-exporter/bin/solr-exporter -p 9854 -z ${ZK_HOSTS}${ZK_CHROOT} -f /opt/solr/contrib/prometheus-exporter/conf/solr-exporter-config.xml -n 2

#!/bin/bash

# Make Bash intolerant to errors
set -o nounset
set -o errexit
set -o pipefail

JDK_TGZ="/tmp/setup/openjdk-11.tgz"
if [ "$JAVA_VERSION" = "1.8" ]
then
    JDK_TGZ="/tmp/setup/openjdk-1.8.tgz"
fi
ZK_TGZ="/tmp/setup/zookeeper-${ZK_VERSION}.tar.gz"


# JDK_DOWNLOAD_PATH="/tmp/jdk.tgz"
# SOLR_DOWNLOAD_PATH="/tmp/solr.tgz"

function expand_tgz() {
    local compressed_file_path="$1"
    local destination_dir_path="$2"
    local extra_tar_args="${@:3}"
    tar \
        --extract \
        --directory "${destination_dir_path}" \
        --file "${compressed_file_path}" \
        ${extra_tar_args}
}


function deploy_jdk_distribution() {
    mkdir --parents "${JDK_DISTRIBUTION_PATH}"
    expand_tgz \
        "${JDK_TGZ}" \
        "${JDK_DISTRIBUTION_PATH}" \
        --strip-components=1
}

function deploy_zk_distribution() {
    mkdir --parents "${ZK_DISTRIBUTION_PATH}"
    expand_tgz \
        "${ZK_TGZ}" \
        "${ZK_DISTRIBUTION_PATH}" \
        --strip-components=1

    #if [ -d "./apache-$1-bin" ]; then
    #    mv ./apache-$1-bin ./$1
    #fi
}


if [ ! -d "$ZK_DISTRIBUTION_PATH" ]; then
    echo "--- Starting ZK installation" >> /tmp/setup/setup.log
    env >> /tmp/setup/setup.log
    
    echo "Download ZK - https://archive.apache.org/dist/zookeeper/zookeeper-${ZK_VERSION}/zookeeper-${ZK_VERSION}.tar.gz" >> /tmp/setup/setup.log
    cd /tmp/setup

    if [[ $ZK_VERSION = 3.4* ]]; then
        wget -q https://archive.apache.org/dist/zookeeper/zookeeper-$ZK_VERSION/zookeeper-$ZK_VERSION.tar.gz 
    else
        wget -q -O zookeeper-$ZK_VERSION.tar.gz https://archive.apache.org/dist/zookeeper/zookeeper-$ZK_VERSION/apache-zookeeper-$ZK_VERSION-bin.tar.gz
    fi
    wget -O node_exporter.tgz -q https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
    wget -O jmx_prometheus_javaagent.jar -q https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$JMX_EXPORTER_VERSION/jmx_prometheus_javaagent-$JMX_EXPORTER_VERSION.jar
   
    echo "Deploy JDK" >> /tmp/setup/setup.log
    deploy_jdk_distribution

    echo "Deploy ZK" >> /tmp/setup/setup.log
    deploy_zk_distribution

    mkdir $ZK_DISTRIBUTION_PATH/prometheus
    cd $ZK_DISTRIBUTION_PATH/prometheus
    tar xzf /tmp/setup/node_exporter.tgz
    mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter .
    rm -rf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64
    chown -R $ZK_USER: $ZK_DISTRIBUTION_PATH/prometheus

    mkdir $ZK_DISTRIBUTION_PATH/jmx-exporter
    cp /tmp/setup/jmx_prometheus_javaagent.jar $ZK_DISTRIBUTION_PATH/jmx-exporter/.
    touch $ZK_DISTRIBUTION_PATH/jmx-exporter/jmx-exporter.yml
    chown -R $ZK_USER: $ZK_DISTRIBUTION_PATH/jmx-exporter
fi


if [ ! -d "$ZK_LOG_PATH" ]; then
    echo "--- Setup ZK logs" >> /tmp/setup/setup.log
    mkdir -p $ZK_LOG_PATH
fi
chown -R $ZK_USER: $ZK_LOG_PATH


if [ ! -d "$ZK_DATA_PATH" ]; then
    echo "--- Setup ZK data" >> /tmp/setup/setup.log
    mkdir -p $ZK_DATA_PATH
    echo $ZK_ID > $ZK_DATA_PATH/myid
    mkdir -p ${ZK_DATA_PATH}_log
fi
chown -R $ZK_USER: $ZK_DATA_PATH
chown -R $ZK_USER: ${ZK_DATA_PATH}_log

cp /tmp/setup/zoo.cfg $ZK_DISTRIBUTION_PATH/conf/.
cp /tmp/setup/zookeeper-env.sh $ZK_DISTRIBUTION_PATH/conf/.
cp /tmp/setup/log4j.properties $ZK_DISTRIBUTION_PATH/conf/.

sed -i /JAVA_HOME=/c\JAVA_HOME=$JDK_DISTRIBUTION_PATH $ZK_DISTRIBUTION_PATH/conf/zookeeper-env.sh

# sed -i /SOLR_HOST/c\SOLR_HOST=$SOLR_HOST /opt/solr/solr/bin/solr.in.sh
# sed -i /SOLR_HEAP/c\SOLR_HEAP=$SOLR_HEAP /opt/solr/solr/bin/solr.in.sh
# sed -i /ZK_/d /opt/solr/solr/bin/solr.in.sh

su -c "$ZK_DISTRIBUTION_PATH/bin/zkServer.sh start" - "$ZK_USER"

export JAVA_HOME=$JDK_DISTRIBUTION_PATH
$ZK_DISTRIBUTION_PATH/prometheus/node_exporter &

#sleep 10
#PID=`ps -ef | grep 'openjdk' | grep -v grep | awk '{print $2}'`
#while kill -0 $PID 2> /dev/null; do
#    sleep 1
#done

tail -f /var/log/lastlog
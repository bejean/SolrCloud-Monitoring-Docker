#!/bin/bash

# Make Bash intolerant to errors
set -o nounset
set -o errexit
set -o pipefail

echo "----------------------------------------"
env
echo "----------------------------------------"


JDK_TGZ="/tmp/setup/openjdk-11.tgz"
if [[ "$SOLR_VERSION" =~ ^(4|5|6|7)[.].*$ ]]
then
    JDK_TGZ="/tmp/setup/openjdk-1.8.tgz"
fi
SOLR_TGZ="/tmp/setup/solr-${SOLR_VERSION}.tgz"

FIRST_STARTUP="0"

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

function deploy_solr_distribution() {
    mkdir --parents "${SOLR_DISTRIBUTION_PATH}"
    expand_tgz \
        "${SOLR_TGZ}" \
        "${SOLR_DISTRIBUTION_PATH}" \
        --strip-components=1
}

if [[ $SOLR_HOST =~ [0-9]$ ]]; then
    echo "Cloud mode"
else
    echo "Standalone mode"
fi

if [ ! -d "$SOLR_DISTRIBUTION_PATH" ]; then
    FIRST_STARTUP="1"

    echo "Starting Solr installation"
    
    echo "Download Solr - http://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz"
    cd /tmp/setup
    if [ -f "/opt/packages/solr-${SOLR_VERSION}.tgz" ]; then
        cp /opt/packages/solr-${SOLR_VERSION}.tgz .
    else
        wget -q http://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz
        if [[ $SOLR_HOST =~ 1$ ]] || [ "x$SOLR_HOST" == "x" ]; then
            cp solr-${SOLR_VERSION}.tgz /opt/packages/.
        fi
    fi
    wget -O node_exporter.tgz -q https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
    wget -O jmx_prometheus_javaagent.jar -q https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$JMX_EXPORTER_VERSION/jmx_prometheus_javaagent-$JMX_EXPORTER_VERSION.jar
    wget -O promtail.zip -q https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip

    echo "Deploy JDK" 
    deploy_jdk_distribution

    echo "Deploy SOLR" 
    deploy_solr_distribution
    chown -R $SOLR_USER: $SOLR_DISTRIBUTION_PATH

    echo "Deploy Node exporter" 
    mkdir $SOLR_DISTRIBUTION_PATH/prometheus
    cd $SOLR_DISTRIBUTION_PATH/prometheus
    tar xzf /tmp/setup/node_exporter.tgz
    mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter .
    rm -rf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64
    chown -R $SOLR_USER: $SOLR_DISTRIBUTION_PATH/prometheus

    echo "Deploy JMX exporter" 
    mkdir $SOLR_DISTRIBUTION_PATH/jmx-exporter
    cp /tmp/setup/jmx_prometheus_javaagent.jar $SOLR_DISTRIBUTION_PATH/jmx-exporter/.
    #cp /tmp/setup/jmx-exporter.yml $SOLR_DISTRIBUTION_PATH/jmx-exporter/.
    touch $SOLR_DISTRIBUTION_PATH/jmx-exporter/jmx-exporter.yml
    chown -R $SOLR_USER: $SOLR_DISTRIBUTION_PATH/jmx-exporter

    echo "Deploy Promtail" 
    mkdir $SOLR_DISTRIBUTION_PATH/promtail
    cd $SOLR_DISTRIBUTION_PATH/promtail
    unzip /tmp/setup/promtail.zip
    cp /tmp/setup/promtail.yml .
    sed -i s/SOLR_HOST/${SOLR_HOST}/g $SOLR_DISTRIBUTION_PATH/promtail/promtail.yml 
    chown -R $SOLR_USER: $SOLR_DISTRIBUTION_PATH/promtail
fi

if [ ! -d "$SOLR_LOG_PATH" ]; then
    echo "Setup Solr logs : $SOLR_LOG_PATH" 
    mkdir -p $SOLR_LOG_PATH
fi
chown -R $SOLR_USER: $SOLR_LOG_PATH


if [ ! -d "$SOLR_DATA_PATH" ]; then
    echo "Setup Solr home : $SOLR_DATA_PATH" 
    mkdir -p $SOLR_DATA_PATH
    cp -r $SOLR_DISTRIBUTION_PATH/server/solr/* $SOLR_DATA_PATH/.
fi
chown -R $SOLR_USER: $SOLR_DATA_PATH

cp /tmp/setup/solr.in.sh $SOLR_DISTRIBUTION_PATH/bin/.
sed -i /SOLR_JAVA_HOME=/c\SOLR_JAVA_HOME=$JDK_DISTRIBUTION_PATH $SOLR_DISTRIBUTION_PATH/bin/solr.in.sh
sed -i /SOLR_HOST=/c\SOLR_HOST=$SOLR_HOST $SOLR_DISTRIBUTION_PATH/bin/solr.in.sh
sed -i /SOLR_HEAP=/c\SOLR_HEAP=$SOLR_HEAP $SOLR_DISTRIBUTION_PATH/bin/solr.in.sh
if [ ! -z "$ZK_CHROOT" ]
then
    echo "Configure Zookeeper chroot mode" 
    sed -i /ZK_HOST=/c\ZK_HOST="$ZK_HOSTS$ZK_CHROOT" $SOLR_DISTRIBUTION_PATH/bin/solr.in.sh
    echo "    Pause (30s)" 
    sleep 30
    if [[ $SOLR_HOST =~ 1$ ]] && [ "x$FIRST_STARTUP" == "x1" ]; then
        echo "    Create Zookeeper chroot node $ZK_CHROOT" 
        su -c "$SOLR_DISTRIBUTION_PATH/bin/solr zk mkroot $ZK_CHROOT -z zk1:2181" - "$SOLR_USER"
    fi
    echo "    Pause (15s)" 
    sleep 15
fi
if [[ ! $SOLR_HOST =~ [0-9]$ ]]; then
    sed -i /ZK_/d $SOLR_DISTRIBUTION_PATH/bin/solr.in.sh
fi
while IFS='=' read -r name value ; do
  if [[ $name == 'solr_sysprop_'* ]]; then
    echo "SOLR_OPTS=\"\$SOLR_OPTS -D${name:13}=${value}\"" >> $SOLR_DISTRIBUTION_PATH/bin/solr.in.sh
  fi
done < <(env)

echo "Start Solr and exporters" 
su -c "$SOLR_DISTRIBUTION_PATH/bin/solr start" - "$SOLR_USER"

export JAVA_HOME=$JDK_DISTRIBUTION_PATH
$SOLR_DISTRIBUTION_PATH/prometheus/node_exporter &
$SOLR_DISTRIBUTION_PATH/promtail/promtail-linux-amd64 -config.file $SOLR_DISTRIBUTION_PATH/promtail/promtail.yml &

if [[ "$SOLR_VERSION" =~ ^(7|8|9)[.].*$ ]] && [ "x$FIRST_STARTUP" == "x1" ]
then
    echo "First startup initiate first collection" 
    echo "    Pause (30s)" 
    sleep 30
    if [[ $SOLR_HOST =~ 1$ ]] 
    then
        su -c "$SOLR_DISTRIBUTION_PATH/bin/solr create_collection -c first -shards 2 -replicationFactor 2" - "$SOLR_USER"
    else
        su -c "$SOLR_DISTRIBUTION_PATH/bin/solr create_core -c first" - "$SOLR_USER"
    fi
fi
#sleep 10
#PID=`ps -ef | grep 'openjdk' | grep -v grep | awk '{print $2}'`
#while kill -0 $PID 2> /dev/null; do
#    sleep 1
#done

tail -f /var/log/lastlog

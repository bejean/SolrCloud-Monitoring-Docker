FROM debian:10
MAINTAINER bejean

RUN apt -y update && apt -y install wget

RUN mkdir /tmp/setup && cd /tmp/setup && \
    wget -O openjdk-1.8.tgz -q https://download.java.net/openjdk/jdk8u41/ri/openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz && \
    wget -O openjdk-11.tgz -q https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz

RUN apt -y install netcat net-tools procps lsof dos2unix vim unzip

ENV \
    SOLR_VERSION=${SOLR_VERSION} \
    NODE_EXPORTER_VERSION=${NODE_EXPORTER_VERSION} \
    JMX_EXPORTER_VERSION=${JMX_EXPORTER_VERSION} \
    PROMTAIL_VERSION=${PROMTAIL_VERSION} \
    SOLR_HEAP=${SOLR_HEAP} \
    SOLR_HOST=${SOLR_HOST} \
    ZK_HOSTS=${ZK_HOSTS} \
    ZK_CHROOT=${ZK_CHROOT} \
    SOLR_DISTRIBUTION_PATH=/opt/solr/solr \
    JDK_DISTRIBUTION_PATH=/opt/solr/jdk \
    JAVA_HOME=/opt/solr/jdk \
    SOLR_USER=solr \
    SOLR_DATA_PATH=/opt/solr/data \
    SOLR_LOG_PATH=/opt/solr/log


RUN useradd -ms /bin/bash ${SOLR_USER}

ADD solr.in.sh /tmp/setup/solr.in.sh
ADD promtail.yml /tmp/setup/promtail.yml
#ADD jmx-exporter.yml /tmp/setup/jmx-exporter.yml

ADD entrypoint.sh /tmp/entrypoint.sh
RUN dos2unix /tmp/entrypoint.sh && chmod +x /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]

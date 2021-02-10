FROM debian:10
MAINTAINER bejean

RUN apt -y update && apt -y install wget

RUN mkdir /tmp/setup && cd /tmp/setup && \
    wget -O openjdk-1.8.tgz -q https://download.java.net/openjdk/jdk8u41/ri/openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz && \
    wget -O openjdk-11.tgz -q https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz

RUN apt -y install netcat net-tools procps lsof dos2unix vim unzip

ENV \
    JAVA_VERSION=${JAVA_VERSION} \
    ZK_VERSION=${ZK_VERSION} \
    NODE_EXPORTER_VERSION=${NODE_EXPORTER_VERSION} \
    JMX_EXPORTER_VERSION=${JMX_EXPORTER_VERSION} \
    ZK_DISTRIBUTION_PATH=/opt/zk/zk \
    JDK_DISTRIBUTION_PATH=/opt/zk/jdk \
    ZK_USER=zookeeper \
    ZK_DATA_PATH=/opt/zk/data \
    ZK_LOG_PATH=/opt/zk/log

RUN useradd -ms /bin/bash ${ZK_USER}

ADD zoo.cfg /tmp/setup/zoo.cfg
ADD zookeeper-env.sh /tmp/setup/zookeeper-env.sh
ADD log4j.properties /tmp/setup/log4j.properties

ADD entrypoint.sh /tmp/entrypoint.sh
RUN dos2unix /tmp/entrypoint.sh && chmod +x /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]

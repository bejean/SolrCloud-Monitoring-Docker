JAVA_HOME=
JAVA="$JAVA_HOME/bin/java"
JAVA_VER=$("$JAVA" -version 2>&1)
JAVA_VER_NUM=$(echo $JAVA_VER | head -1 | awk -F '"' '/version/ {print $2}' | sed -e's/^1\.//' | sed -e's/[._-].*$//')
echo "Java version $JAVA_VER_NUM"

# Configure Log 
ZOO_LOG_DIR="/opt/zk/log" 
ZOO_LOG4J_PROP="WARN, ROLLINGFILE" 
ZOO_GC_LOG_DIR="$ZOO_LOG_DIR" 

# Configure mémoire JVM selon la mémoire disponible
SERVER_JVMFLAGS="-Xmx512m"
SERVER_JVMFLAGS="$SERVER_JVMFLAGS -javaagent:/opt/zk/zk/jmx-exporter/jmx_prometheus_javaagent.jar=7070:/opt/zk/zk/jmx-exporter/jmx-exporter.yml"

# Configure JMX (enabled by default for local monitoring by PID)
JMXDISABLE=true
JMXPORT=10900

# Configure JVM GC and log 
if [[ "$JAVA_VER_NUM" -lt "9" ]] ; then
  SERVER_JVMFLAGS="$SERVER_JVMFLAGS -verbose:gc -XX:+PrintHeapAtGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps" 
  SERVER_JVMFLAGS="$SERVER_JVMFLAGS -XX:+PrintGCTimeStamps -XX:+PrintTenuringDistribution -XX:+PrintGCApplicationStoppedTime"
  SERVER_JVMFLAGS="$SERVER_JVMFLAGS -Xloggc:$ZOO_GC_LOG_DIR/zookeeper-gc.log" 
  SERVER_JVMFLAGS="$SERVER_JVMFLAGS -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=20M" 
else
  # Use G1GC
  SERVER_JVMFLAGS="$SERVER_JVMFLAGS -XX:+UseG1GC -XX:MaxGCPauseMillis=100"
  #SERVER_JVMFLAGS="-XX:+PerfDisableSharedMem -XX:+ParallelRefProcEnabled -XX:+UseLargePages -XX:+AlwaysPreTouch"
  SERVER_JVMFLAGS="$SERVER_JVMFLAGS -Xlog:gc*:file=$ZOO_GC_LOG_DIR/zookeeper-gc.log:time,uptime:filecount=10,filesize=20M"
fi

# Backup des logs GC au démarrage (sinon ils sont perdus)
if [ "x$1" = "xstart" ]; then
    for f in $ZOO_GC_LOG_DIR/zookeeper-gc.log*; do
        ## Check if the glob gets expanded to existing files.
        ## If not, f here will be exactly the pattern above
        ## and the exists test will evaluate to false.
        if [ -e "$f" ] ; then
            echo "GC log files found - backing up"
            d=$PWD && cd $ZOO_GC_LOG_DIR && tar czf zookeeper-gc.$(date +%Y%m%d-%H%M%S).tgz zookeeper-gc.log* && cd $d
        else
            echo "No GC log files found"
        fi
        ## This is all we needed to know, so we can break after the first iteration
        break
    done
fi
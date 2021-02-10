SOLR_JAVA_HOME="/usr/local/openjdk-11"
# la taille de la mémoire heap nécessaire
SOLR_HEAP="4g"
# lors d'une installation en mode Solrcloud, indiquer le liste des serveurs Zookeeper
ZK_HOST="zk1:2181,zk2:2181,zk3:2181"
ZK_CLIENT_TIMEOUT="30000"
# le nom de host de ce serveurs solr tel qu'indiqué dans /etc/hosts
SOLR_HOST="solr1"
SOLR_PORT="8983"
# selon le paramètre -d du script d'installation
SOLR_PID_DIR="/opt/solr/solr"
SOLR_HOME="/opt/solr/data"
#LOG4J_PROPS="/opt/solr/conf/log4j.properties"
SOLR_LOGS_DIR="/opt/solr/log"

SOLR_OPTS="$SOLR_OPTS -javaagent:/opt/solr/solr/jmx-exporter/jmx_prometheus_javaagent.jar=7070:/opt/solr/solr/jmx-exporter/jmx-exporter.yml"

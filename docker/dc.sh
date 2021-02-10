#!/bin/bash
usage(){
    echo ""
    echo "Usage : $0 -a action -p project_name";
    echo ""
    echo "    -a action         : up | stop | down | clean";
    echo "    -p project_name   : project_name in order to be create relevant .env file";
    echo "    -m mode           : solr mode (monitoring | cloud | standalone)";
    echo ""
    echo "  Example : $0 -a up -p minnie"
    echo ""
    exit 1
}
history(){
    DATE="`date +%Y/%m/%d-%H:%M:%S`"
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    echo "$DATE - $0 $1" >> $DIR/history.txt
}

if [ "$1" == "-h" ] ; then 
    usage
fi

export ACTION=
export PROJECT=
export MODE=

if [ $# -gt 1 ]; then
    while getopts ":a:p:m:" opt; do
        case $opt in
            a) export ACTION=$OPTARG ;;
            p) export PROJECT=$OPTARG ;;
            m) export MODE=$OPTARG ;;
            *) usage "$1: unknown option" ;;
        esac
    done
fi

if [ -z "$ACTION" ] ; then
    echo "ERROR : Missing parameter : -a action"
    usage
fi

if [[ ! "$ACTION" =~ ^(up|stop|down|clean)$ ]]; then
    echo "ERROR: Unknown action!"
    usage
fi

if [[ ! "$MODE" =~ ^(monitoring|cloud|standalone)$ ]]; then
    echo "ERROR: Unknown mode!"
    usage
fi

if [ -z "$PROJECT" ] ; then
    echo "ERROR : Missing parameter : -p project_name"
    usage
fi

if [ ! -f "env/$PROJECT" ]; then
    echo "env/$PROJECT not found"
    usage
fi

cp env/$PROJECT .env

history "$*"


if [ "$ACTION" == "up" ] ; then 
    if [ "$MODE" == "monitoring" ] ; then 
        if [ -f "env/${PROJECT}.docker-compose.yml" ] ; then 
            docker-compose -f docker-compose-monitoring.yml -f env/${PROJECT}.docker-compose.yml up -d --build
        else
            docker-compose -f docker-compose-monitoring.yml up -d --build
        fi
    else
        if [ "$MODE" == "standalone" ] ; then 
            COMPOSE_FILE="docker-compose-standalone.yml"
        else
            COMPOSE_FILE="docker-compose-cloud.yml"
        fi
        if [ -f "env/${PROJECT}.docker-compose.yml" ] ; then 
            docker-compose -f $COMPOSE_FILE -f docker-compose-monitoring.yml -f env/${PROJECT}.docker-compose.yml up -d --build
        else
            docker-compose -f $COMPOSE_FILE -f docker-compose-monitoring.yml up -d --build
        fi
    fi
fi

if [ "$ACTION" == "stop" ] ; then 
    if [ "$MODE" == "monitoring" ] ; then 
        docker-compose -f docker-compose-monitoring.yml stop
    else
        docker-compose -f $COMPOSE_FILE -f docker-compose-monitoring.yml stop
    fi
fi

if [ "$ACTION" == "down" ] ; then 
    if [ "$MODE" == "monitoring" ] ; then 
        docker-compose -f docker-compose-monitoring.yml down
    else
        docker-compose -f $COMPOSE_FILE -f docker-compose-monitoring.yml down
    fi
fi

if [ "$ACTION" == "clean" ] ; then 
    if [ "$MODE" == "monitoring" ] ; then 
        docker-compose -f docker-compose-monitoring.yml down
        docker-compose -f docker-compose-monitoring.yml rm -v
    else
        docker-compose -f $COMPOSE_FILE -f docker-compose-monitoring.yml down
        docker-compose -f $COMPOSE_FILE -f docker-compose-monitoring.yml rm -v
    fi
    docker volume rm $(docker volume ls -q | grep $PROJECT)
fi

rm .env

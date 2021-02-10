#!/bin/bash

usage(){
    echo ""
    echo "Usage : $0 -c container_name [-u user] [-s shell]";
    echo ""
    echo "    -c container_name : container name";
    echo "    -u user           : user to log in (default root)";
    echo "    -s shell          : bash (default) or sh";
    echo ""
    echo "  Example : $0 -c solr01 -u solr -s sh"
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

export CONTAINER=
export USER=root
export SHELL=bash

if [ $# -gt 1 ]; then
    while getopts ":c:u:s:" opt; do
        case $opt in
            c) export CONTAINER=$OPTARG ;;
            u) export USER=$OPTARG ;;
            s) export SHELL=$OPTARG ;;
            *) usage "$1: unknown option" ;;
        esac
    done
fi

if [ -z "$CONTAINER" ] ; then
    echo "ERROR : Missing parameter : -c container_name"
	usage
fi

history "$*"

if [ "$SHELL" == "bash" ] ; then 
    docker exec -i -u $USER -t $CONTAINER /bin/bash -c "export COLUMNS=`tput cols`; export LINES=`tput lines`; exec bash"
else
    docker exec -i -u $USER -t $CONTAINER /bin/sh -c "export COLUMNS=`tput cols`; export LINES=`tput lines`; exec sh"
fi

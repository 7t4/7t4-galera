#!/usr/bin/env bash -e
#
# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ ! -z "$DEBUG" && "$DEBUG" != 0 && "${DEBUG^^}" != "FALSE" ]]; then
  set -x
fi

function node_address(){
    while [[ -z "$NODE_ADDRESS" ]] ; do
        NODE_ADDRESS="$(hostname -i | awk '{print $1}')"
        if [[ -z "$NODE_ADDRESS" ]] ; then
	    echo "Waiting for dns..." >&2
       	    sleep 1;
	    LOOP=$((LOOP + 1));
        fi
    done
    echo "$NODE_ADDRESS"
}

function fqdn(){
    while [[ -z "$FQDN" && $LOOP -lt 30 ]] ; do
        FQDN="$(nslookup "$(node_address)" | awk -F'= ' 'NR==5 { print $2 }')"
        SERVICE_NAME="$(echo "$FQDN" | awk -F'.' '{print $1}')"
# TODO: fix this. getent may be an issue.
#      Not sure if we need this loop anyway.
#        SERVICE_LOOKUP="$(getent hosts tasks.${SERVICE_NAME})"
#        if [[ -z "${SERVICE_LOOKUP}" ]]; then
#            FQDN=""
#        fi
    done
    echo "$FQDN"
}

function service_hostname(){
    SERVICE_HOSTNAME="${SERVICE_NAME:="$(echo "$(fqdn)" | awk -F'.' '{print $1 "." $2}')"}"
    echo "$SERVICE_HOSTNAME"
}

function service_name(){
    SERVICE_NAME="${SERVICE_NAME:="$(echo "$(fqdn)" | awk -F'.' '{print $1}')"}"
    echo "$SERVICE_NAME"
}

function service_instance(){
    SERVICE_INSTANCE="${SERVICE_INSTANCE:="$(echo "$(fqdn)" | awk -F'.' '{print $2}')"}"
    echo "$SERVICE_INSTANCE"
}

function container_name(){
    if [[ -z $CONTAINER_NAME ]] ; then
        SERVICE_NAME="$(service_name)"
        CONTAINER_NAME="${SERVICE_NAME##*_}"
    fi
    echo "$CONTAINER_NAME"
}

function service_members(){
  # getent doesn't work with alpine (something about nsswitch.conf)
  # we assume the output format for nslookup is uniform
#    SERVICE_MEMBERS="$(getent hosts tasks.$(service_name) | cut -d ' ' -f 1 | while read ip; do nslookup $ip | awk -v "ip=$ip" '(NR == 5){print ip,$0}'; done | sort -k3 | awk -v 'ORS=,' '{print $1}')"
#    SERVICE_MEMBERS="${SERVICE_MEMBERS%%,}" # strip trailing commas
    SERVICE_MEMBERS="$(nslookup tasks.$(service_name) | grep Addr | grep -v :53 | awk '{print $2}' | paste -s -d, -)"
    echo "${SERVICE_MEMBERS}"
}

function service_count(){
    SERVICE_COUNT=$(echo "$(service_members)" | tr ',' ' ' | wc -w)
    echo $SERVICE_COUNT
}

function main(){
    case "$1" in
        -a|--address)
	    echo "$(node_address)"
            ;;
        -c|--container)
	    echo "$(container_name)"
            ;;
        -i|--instance)
	    echo "$(service_instance)"
            ;;
        -f|--fqdn)
	    echo "$(fqdn)"
            ;;
        -h|--hostname)
	    echo "$(service_hostname)"
            ;;
        -s|--service)
	    echo "$(service_name)"
            ;;
    esac
}

main "$@"

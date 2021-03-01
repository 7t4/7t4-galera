#!/bin/bash

set -eo pipefail
shopt -s nullglob

source "galera_common.sh"

declare WANTHELP=$(echo "$@" | grep '\(-?\|--help\|--print-defaults\|-V\|--version\)')
declare -a cmd=( "$*" )

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ -n "$DEBUG" ]]; then
    set -x
fi

# if command starts with an option, prepend mysqld
if [[ "${1:0:1}" = '-' ]]; then
    set -- mysqld "$@"
fi

# command is not mysqld
if [[ $1 != 'mysqld' && $1 != 'mysqld_safe' ]]; then
    exec "$@"
fi

# command has help param
if [[ ! -z "$WANTHELP" ]]; then
    exec "$@"
fi

# allow the container to be started with `--user`
# uh.. or if root run as mysql ??
if [[ "$(id -u)" = '0' ]]; then
    exec su-exec mysql "$BASH_SOURCE" "$@"
fi

# Set env MYSQLD_INIT to trigger setup
if [[ ! -d "$(mysql_datadir)/mysql" ]]; then
    MYSQLD_INIT=${MYSQLD_INIT:=1}
fi

# Configure database if MYSQLD_INIT is set
if [[ ! -z "${MYSQLD_INIT}" ]]; then
    source "mysql_init.sh"
fi

# Set env to trigger creation of galera.cnf
if [[ ! -f "$(galera_cnf)" ]]; then
    GALERA_INIT=${GALERA_INIT:=1}
fi

# create galera.cnf
if [[ ! -z "${GALERA_INIT}" ]]; then
    source "galera_init.sh"
    # new node, see if we are task 1 of service
    if [[ ! -z "$(is_primary_component)" ]]; then
       cmd+=( " --wsrep-new-cluster" )
    fi
else
  # update cluster addresses, etc.
  source "update_conf.sh"
fi

#TODO: Is this necessary???
# Attempt recovery if possible
if [[ -f "$(grastate_dat)" ]]; then
    mysqld ${cmd[@]:1} --wsrep-recover
fi

# Either node crashed or...
# we are using host vol bind mounts and have started on a host already running a container.
# Other methods of preventing the latter should be enforced so we don't have to consider that case here.
#if [[ -f "$(gvwstate_dat)" ]]; then
# do we need to decide if safe_to_bootstrap?? or will galera figure it out?
#    mysqld ${cmd[@]:1} --wsrep-recover
#fi

# bootstrap
if [ "$(cluster_stb)" == "1" ]; then
  # appears that entire cluster was shutdown normally
  # or grastate.dat was manually edited
    cmd+=( " --wsrep-new-cluster" )
fi

echo "entry passing to $cmd"
#tail -f /var/log/mysql/error.log &
exec ${cmd[*]} 2>&1

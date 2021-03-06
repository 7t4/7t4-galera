#!/bin/bash -e
#

[[ -z "$DEBUG" ]] || set -x

declare MYSQL_CONFD="${MYSQL_CONFD:="/etc/mysql/conf.d"}"
declare DATADIR="${DATADIR:="/var/lib/mysql"}"

function mysql_datadir(){
    echo "$DATADIR"
}

function mysql_confd(){
    mkdir -p "${MYSQL_CONFD}"
    echo "$MYSQL_CONFD"
}

function mysql_user(){
    if [[ -n "$1" ]]; then
        USER="$1"
    else
        USER=${MYSQL_USER:="root"}
    fi
    echo "$USER"
}

function wsrep_user(){
    #WSREP_USER="${WSREP_USER:="xtrabackup"}"
    WSREP_USER="${WSREP_USER:="mariabackup"}"
    echo "$WSREP_USER"
}

function mysql_password(){
    USER="$(mysql_user $1)"
    if [[ $USER == "root" ]]; then
        PASSWORD="${MYSQL_ROOT_PASSWORD:="${MYSQL_ROOT_PASSWORD_FILE}"}"
    elif [[ $USER == "${MYSQL_USER}" ]]; then
        PASSWORD="${MYSQL_PASSWORD:="${MYSQL_PASSWORD_FILE}"}"
    fi

    if [[ -r "$PASSWORD" ]]; then
        PASSWORD="$(cat "$PASSWORD")"
    elif [[ -z "$PASSWORD" && -r "/var/run/secrets/$USER" ]]; then
        PASSWORD="$(cat "/var/run/secrets/${USER}")"
    elif [[ -z "$PASSWORD" ]]; then
        PASSWORD="$(echo "$USER:$MYSQL_ROOT_PASSWORD" | sha256sum | awk '{print $1}')"
    fi

    echo "${PASSWORD}"
}

function mysql_shutdown(){
    NETON="$(nc -z 127.0.0.1 3306; echo $?)"
    MYSQL_SHUT=( "mysqladmin" )
    MYSQL_SHUT+=( "shutdown" )
    MYSQL_SHUT+=( "-u$(mysql_user root)" )
    MYSQL_SHUT+=( "-p$(mysql_password root)" )
    if [[ -S /var/run/mysqld/mysqld.sock ]]; then
      MYSQL_SHUT+=( " --socket=/var/run/mysqld/mysqld.sock" )
    elif [[ "${NETON}" == "0" ]]; then
      MYSQL_SHUT+=( "--protocol=tcp -h127.0.0.1")
    fi
    echo "${MYSQL_SHUT[@]}"
}

function mysql_client(){
    MYSQL_CLIENT=( "mysql" )
    MYSQL_CLIENT+=( "--protocol=socket" )
    MYSQL_CLIENT+=( "--socket=/var/run/mysqld/mysqld.sock" )
    MYSQL_CLIENT+=( "-hlocalhost" )
    MYSQL_CLIENT+=( "-u$(mysql_user root)" )
    MYSQL_CLIENT+=( "-p$(mysql_password root)" )
    echo "${MYSQL_CLIENT[@]}"
}

function main(){
    case "$1" in
        -a|--auth)
            echo "$(mysql_auth $2)"
            ;;
        -d|--dir)
            echo "$(mysql_datadir)"
            ;;
        -p|--password)
            echo "$(mysql_password $2)"
            ;;
        -u|--user)
            echo "$(mysql_user $2)"
            ;;
    esac
}

main "$@"

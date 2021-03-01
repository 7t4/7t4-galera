#!/usr/bin/env bash


sed -i '/wsrep-cluster-address=/c wsrep-cluster-address='$(wsrep_cluster_address)'' $(galera_cnf)

#if [[ -n "$DEBUG" ]]; then
#  env > /var/log/mysql/env-debug.log
#fi
# update any other passed vars
echo "`env`" | while IFS='=' read -r NAME VALUE
  do
      sed -i "s#{{${NAME}}}#${VALUE}#g" $(galera_cnf)
  done

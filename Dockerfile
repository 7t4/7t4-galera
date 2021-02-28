FROM alpine:latest


RUN addgroup -g 1001 -S mysql && \
    adduser -u 1001 -S mysql -G mysql


RUN mkdir /var/run/mysqld && \
    apk -U upgrade && \
    apk add --no-cache mariadb mariadb-client mariadb-backup && \
    apk add --no-cache tzdata bash su-exec && \
    apk add galera --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ && \
    chown -R mysql:mysql /etc/mysql && \
    chown -R mysql:mysql /var/run/mysqld && \
    rm -rf /var/cache/apk/* && \
    # always run as user mysql
    sed -i '/^\[mysqld]$/a user=mysql' /etc/my.cnf && \
    # allow custom configurations
    echo -e '\n!includedir /etc/mysql/conf.d/' >> /etc/my.cnf

    # using a vol bind mount to /etc/mysql
    #mkdir -p /etc/mysql/conf.d/



#USER 1001

# we expose all Cluster related Ports
# 3306: default MySQL/MariaDB listening port
# 4444: for State Snapshot Transfers
# 4567: Galera Cluster Replication
# 4568: Incremental State Transfer
EXPOSE 3306 4444 4567 4567/udp 4568

COPY rootfs/ /

ENTRYPOINT ["/usr/local/bin/galera-entrypoint.sh"]
CMD ["mysqld"]

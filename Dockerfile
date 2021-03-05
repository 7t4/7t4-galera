FROM alpine:edge


RUN addgroup -g 1001 -S mysql && \
    adduser -u 1001 -S mysql -G mysql


RUN mkdir /var/run/mysqld && \
    apk -U upgrade && \
    apk add --no-cache tzdata bash su-exec socat iproute2-ss pv && \
    apk add --no-cache mariadb mariadb-client mariadb-backup mariadb-server-utils && \
    apk add --no-cache galera && \
    # --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ && \
    chown -R mysql:mysql /etc/mysql && \
    chown -R mysql:mysql /var/run/mysqld && \
    rm -rf /var/cache/apk/* && \
    sed -i '/!includedir /c !includedir /etc/mysql/conf.d/' /etc/my.cnf
    # Overwrite default include path which includes a cnf containing skip-networking
    # echo -e '\n!includedir /etc/mysql/conf.d/' >> /etc/my.cnf

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

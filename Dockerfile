FROM alpine:latest


RUN addgroup -g 1001 -S mysql && \
    adduser -u 1001 -S mysql -G mysql


RUN mkdir /docker-entrypoint-initdb.d && \
    apk -U upgrade && \
    apk add --no-cache mariadb mariadb-client && \
    apk add --no-cache tzdata bash && \
    # clean up
    rm -rf /var/cache/apk/*


USER 1001

# we expose all Cluster related Ports
# 3306: default MySQL/MariaDB listening port
# 4444: for State Snapshot Transfers
# 4567: Galera Cluster Replication
# 4568: Incremental State Transfer
EXPOSE 3306 4444 4567 4567/udp 4568

COPY rootfs/ /

ENTRYPOINT ["/usr/local/bin/galera-entrypoint.sh"]
CMD ["mysqld"]

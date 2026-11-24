FROM mysql:8.0 AS primary
COPY --chmod=644 conf/primary.cnf /etc/mysql/conf.d/primary.cnf

FROM mysql:8.0 AS replica
COPY --chmod=644 conf/replica.cnf /etc/mysql/conf.d/replica.cnf

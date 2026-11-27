#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
umask 077

wait_replica() {
    local gtids
    gtids=$(db primary -NB -e 'SELECT @@GLOBAL.gtid_executed')
    [[ $gtids =~ ^[a-fA-F0-9,:-]+$ ]]
    [[ $(db replica -NB -e "SELECT WAIT_FOR_EXECUTED_GTID_SET('$gtids', 20)") == 0 ]]
}

case "${1:-}" in
    setup)
        if [[ $(db replica -NB -e 'SELECT @@server_id') != 2 ||
              -n $(db replica -NB -e 'SHOW REPLICA STATUS') ||
              $(db replica -NB -e "SELECT COUNT(*) FROM information_schema.schemata
                   WHERE schema_name NOT IN ('mysql','sys','information_schema','performance_schema')") != 0 ]]; then
            printf 'Для початкового завантаження потрібна порожня replica без каналу реплікації.\n' >&2
            exit 1
        fi
        replica_gtids=$(db replica -NB -e 'SELECT @@GLOBAL.gtid_executed')
        if [[ -n $replica_gtids ]]; then
            replica_uuid=$(db replica -NB -e 'SELECT @@server_uuid')
            if [[ ${2:-} != --reset-empty-replica ||
                  $replica_gtids != "$replica_uuid":* || $replica_gtids == *,* ]]; then
                printf 'GTID репліки: %s\n' "$replica_gtids" >&2
                printf 'Для нової порожньої replica з власними GTID використайте setup --reset-empty-replica.\n' >&2
                exit 1
            fi
            printf 'Очищення початкових локальних GTID порожньої replica: %s\n' "$replica_gtids"
            db replica -e 'RESET MASTER'
        fi
        mkdir -p "$BACKUP_DIR"
        snapshot=$(mktemp "$BACKUP_DIR/replica_seed.XXXXXXXX")
        trap 'rm -f -- "$snapshot"' EXIT
        docker compose exec -T primary sh -c '
            export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
            exec mysqldump -uroot --single-transaction --source-data=2 --no-tablespaces \
                --set-gtid-purged=ON --routines --triggers --events --databases restaurant_db
        ' > "$snapshot"
        db replica < "$snapshot"
        # Облікові записи створені на primary до знімка; відтворюємо їх без локальних GTID.
        {
            printf 'SET SESSION sql_log_bin=0;\n'
            sed -e "s/@APP_PASSWORD@/$APP_PASSWORD/g" -e "s/@REPORT_PASSWORD@/$REPORT_PASSWORD/g" \
                -e "s/@BACKUP_PASSWORD@/$BACKUP_PASSWORD/g" -e "s/@REPL_PASSWORD@/$REPL_PASSWORD/g" \
                sql/01_users.sql
        } | db replica
        sed "s/@REPL_PASSWORD@/$REPL_PASSWORD/g" sql/02_replication.sql | db replica
        wait_replica
        ;;
    verify)
        wait_replica
        marker="lr5_replica_$(date +%s)_${BASHPID}"
        db primary restaurant_db -e "INSERT INTO food(name, description, price) VALUES ('$marker', 'replication', 1)"
        wait_replica
        printf '\n(a) Запис з primary читається на replica\n'
        db replica restaurant_db -e "SELECT food_id, name FROM food WHERE name='$marker'"
        [[ $(db replica -NB restaurant_db -e "SELECT COUNT(*) FROM food WHERE name='$marker'") == 1 ]]

        db primary <<SQL
CREATE USER IF NOT EXISTS 'viewer'@'%' IDENTIFIED BY '$VIEWER_PASSWORD';
ALTER USER 'viewer'@'%' IDENTIFIED BY '$VIEWER_PASSWORD';
GRANT SELECT ON restaurant_db.* TO 'viewer'@'%';
GRANT INSERT ON restaurant_db.food TO 'viewer'@'%';
SQL
        wait_replica
        printf '\n(б) viewer читає на replica\n'
        LAB_PASSWORD=$VIEWER_PASSWORD
        as_user replica viewer restaurant_db -e "SELECT CURRENT_USER(), name FROM food WHERE name='$marker'"
        insert="INSERT INTO food(name, price) VALUES ('blocked_$marker', 1)"
        printf '\n(в) root: запис заборонено\n'
        expect_error 'ERROR 1290' db replica restaurant_db -e "$insert"
        printf '\n(г) viewer: запис заборонено попри GRANT INSERT\n'
        expect_error 'ERROR 1290' as_user replica viewer restaurant_db -e "$insert"

        printf '\n(д) До START REPLICA та після\n'
        trap 'db replica -e "START REPLICA" >/dev/null 2>&1 || true' EXIT
        db replica -e 'STOP REPLICA'
        db primary restaurant_db -e "INSERT INTO food(name, price) VALUES ('paused_$marker', 1)"
        db replica restaurant_db -e "SELECT COUNT(*) AS before_start FROM food WHERE name='paused_$marker'"
        [[ $(db replica -NB restaurant_db -e "SELECT COUNT(*) FROM food WHERE name='paused_$marker'") == 0 ]]
        db replica -e 'START REPLICA'
        wait_replica
        trap - EXIT
        db replica restaurant_db -e "SELECT COUNT(*) AS after_start FROM food WHERE name='paused_$marker'"
        [[ $(db replica -NB restaurant_db -e "SELECT COUNT(*) FROM food WHERE name='paused_$marker'") == 1 ]]

        printf '\n(е) Видалення тестових записів поширюється на replica\n'
        db primary restaurant_db -e "DELETE FROM food WHERE name IN ('$marker','paused_$marker')"
        wait_replica
        db replica restaurant_db -e "SELECT COUNT(*) AS replica_after_delete FROM food WHERE name IN ('$marker','paused_$marker')"
        [[ $(db replica -NB restaurant_db -e "SELECT COUNT(*) FROM food WHERE name IN ('$marker','paused_$marker')") == 0 ]]
        printf '\nPRIMARY\n'
        db primary -e 'SELECT @@gtid_executed; SHOW REPLICAS;'
        printf '\nREPLICA\n'
        db replica -e 'SELECT @@gtid_executed;'
        primary_gtid=$(db primary -NB -e 'SELECT @@GLOBAL.gtid_executed')
        replica_gtid=$(db replica -NB -e 'SELECT @@GLOBAL.gtid_executed')
        [[ $primary_gtid == "$replica_gtid" ]]
        ;;
    *)
        printf 'Запуск: bash scripts/replication.sh setup [--reset-empty-replica] або verify\n' >&2
        exit 2
        ;;
esac
status=$(db replica -e 'SHOW REPLICA STATUS\G')
printf '%s\n' "$status" | grep -E 'Source_Host:|Replica_IO_Running:|Replica_SQL_Running:|Seconds_Behind_Source:|Last_IO_Error:|Last_SQL_Error:|Auto_Position:'
grep -q 'Replica_IO_Running: Yes$' <<< "$status"
grep -q 'Replica_SQL_Running: Yes$' <<< "$status"

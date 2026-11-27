#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
umask 077
table="lr5_pitr_${BASHPID}"
target="restaurant-lr5-pitr-${BASHPID}"

cleanup() {
    docker rm -f "$target" >/dev/null 2>&1 || true
    db primary -e "DROP TABLE IF EXISTS restaurant_db.$table" >/dev/null
}
db primary restaurant_db -e "CREATE TABLE $table (
    id INT PRIMARY KEY, order_id INT NOT NULL, message VARCHAR(60) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES \`order\` (order_id)
) ENGINE=InnoDB"
trap cleanup EXIT
db primary restaurant_db -e "INSERT INTO $table
    SELECT 1, MIN(order_id), 'before-backup' FROM \`order\`"
file=$(bash scripts/backup.sh)
coordinates=$(gzip -dc "$file" | awk '/^-- CHANGE (MASTER|REPLICATION SOURCE) TO/ && !line {line=$0} END {print line}')
printf '%s\n' "$coordinates"
read -r start_file start_pos <<< "$(sed -nE "s/.*(MASTER|SOURCE)_LOG_FILE='([^']+)', (MASTER|SOURCE)_LOG_POS=([0-9]+).*/\2 \4/p" <<< "$coordinates")"
[[ $start_file =~ ^binlog\.[0-9]+$ && $start_pos =~ ^[0-9]+$ ]]

db primary restaurant_db -e "INSERT INTO $table
    SELECT n.id, o.order_id, 'after-backup'
    FROM (SELECT 2 AS id UNION ALL SELECT 3) AS n
    CROSS JOIN (SELECT MIN(order_id) AS order_id FROM \`order\`) AS o;
    UPDATE $table SET message='updated-after-backup' WHERE id=1"
printf 'До аварії: '
db primary -NB restaurant_db -e "SELECT COUNT(*) FROM $table"
read -r stop_file stop_pos _ <<< "$(db primary -NB -e 'SHOW MASTER STATUS')"
db primary restaurant_db -e "DELETE FROM $table"
printf 'Після аварії: '
db primary -NB restaurant_db -e "SELECT COUNT(*) FROM $table"
if [[ $start_file != "$stop_file" ]]; then
    printf 'Журнал ротувався під час демонстрації. Повторіть запуск.\n' >&2
    exit 1
fi
[[ $stop_pos =~ ^[0-9]+$ ]]
events=$(db primary -NB -e "SHOW BINLOG EVENTS IN '$stop_file' FROM $stop_pos LIMIT 8")
printf 'Межа відновлення: %s, позиція %s\n%s\n' "$stop_file" "$stop_pos" "$events"
awk -F '\t' -v pos="$stop_pos" -v tbl="$table" '
    NR == 1 {gtid=($2 == pos && $3 == "Gtid")}
    $3 == "Table_map" && index($0, "restaurant_db." tbl) {mapped=1}
    $3 == "Delete_rows" && mapped {deleted=1}
    END {exit !(gtid && mapped && deleted)}
' <<< "$events"

export MYSQL_ROOT_PASSWORD
docker run -d --name "$target" --network none --tmpfs /var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD -e MYSQL_ROOT_HOST=localhost mysql:8.0 >/dev/null
target_db() {
    docker exec -i "$target" sh -c '
        export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
        test "$(cat /proc/1/comm)" = mysqld || exit 1
        exec mysql --protocol=SOCKET -uroot --default-character-set=utf8mb4 "$@"
    ' sh "$@"
}
ready=0
for attempt in {1..90}; do
    if target_db -NB -e 'SELECT 1' >/dev/null 2>&1; then ready=1; break; fi
    sleep 1
done
if (( !ready )); then docker logs --tail 30 "$target" >&2; exit 1; fi
target_db -e 'CREATE DATABASE restaurant_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci'
gzip -dc "$file" | target_db restaurant_db
replay=$(mktemp "$BACKUP_DIR/.pitr-replay.XXXXXXXX")
trap 'rm -f -- "$replay"; cleanup' EXIT
binlog_options=(--skip-gtids --database=restaurant_db
    "--start-position=$start_pos" "--stop-position=$stop_pos")
if docker compose exec -T primary sh -c 'command -v mysqlbinlog' </dev/null >/dev/null 2>&1; then
    docker compose exec -T primary mysqlbinlog "${binlog_options[@]}" \
        "/var/lib/mysql/$start_file" > "$replay"
else
    printf 'Читаємо binlog клієнтом MySQL в окремому контейнері Ubuntu.\n'
    docker compose exec -T primary cat "/var/lib/mysql/$start_file" |
        docker run --rm -i ubuntu:22.04 sh -ec '
            apt-get update -qq </dev/null >&2
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
                mysql-server-core-8.0 </dev/null >&2
            cat > /tmp/restaurant.binlog
            exec mysqlbinlog "$@" /tmp/restaurant.binlog
        ' sh "${binlog_options[@]}" > "$replay"
fi
grep -q '^BINLOG ' "$replay"
target_db restaurant_db < "$replay"
printf 'Після відновлення: '
target_db -NB restaurant_db -e "SELECT COUNT(*) FROM $table"
target_db restaurant_db -e "SELECT id, order_id, message FROM $table ORDER BY id"
[[ $(target_db -NB restaurant_db -e "SELECT COUNT(*) FROM $table WHERE (id=1 AND
    message='updated-after-backup') OR (id IN (2,3) AND message='after-backup')") == 3 ]]

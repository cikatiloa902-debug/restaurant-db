#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

db primary restaurant_db <<'SQL'
SELECT SLEEP(1) AS pause;
SELECT SLEEP(0.8) AS lr5_probe, name FROM food
WHERE name LIKE 'Борщ%' ORDER BY food_id LIMIT 1;
EXPLAIN SELECT food_id, name FROM food WHERE name LIKE 'Борщ%';
SQL
docker compose exec -T primary tail -n 20 /var/lib/mysql/slow.log
if docker compose exec -T primary sh -c 'command -v mysqldumpslow >/dev/null'; then
    docker compose exec -T primary mysqldumpslow -s t /var/lib/mysql/slow.log
elif command -v mysqldumpslow >/dev/null; then
    temp_log=$(mktemp)
    trap 'rm -f -- "$temp_log"' EXIT
    docker compose exec -T primary cat /var/lib/mysql/slow.log > "$temp_log"
    mysqldumpslow -s t "$temp_log"
    rm -f -- "$temp_log"
    trap - EXIT
else
    printf 'mysqldumpslow недоступний. Фрагмент slow.log наведено вище.\n' >&2
fi

disable_log() { db primary -e 'SET GLOBAL general_log=OFF' >/dev/null; }
trap disable_log EXIT
db primary -e 'SET GLOBAL general_log=ON'
db primary restaurant_db -e 'SELECT COUNT(*) FROM food; SELECT COUNT(*) FROM drink;'
LAB_PASSWORD=WrongPasswordForLocalLab
expect_error 'ERROR 1045' as_user primary app_user -e 'SELECT 1'
disable_log
trap - EXIT
docker compose exec -T primary sh -c 'grep -E "Connect|Query" /var/lib/mysql/general.log | tail -n 20'
db primary -e 'SHOW BINARY LOGS; SHOW MASTER STATUS;'
log=$(db primary -NB -e 'SHOW MASTER STATUS' | cut -f1)
[[ $log =~ ^binlog\.[0-9]+$ ]]
db primary -e "SHOW BINLOG EVENTS IN '$log' LIMIT 5"

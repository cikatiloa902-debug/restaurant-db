#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
file=${1:?Вкажіть шлях до копії .sql.gz}
gzip -t "$file"
tmp_db="restaurant_verify_$(date +%s)_${BASHPID}"
db primary -e "CREATE DATABASE \`$tmp_db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
trap 'db primary -e "DROP DATABASE \`$tmp_db\`" >/dev/null' EXIT
gzip -dc "$file" | db primary "$tmp_db"

list_tables() {
    db primary -NB -e "SELECT table_name FROM information_schema.tables
        WHERE table_schema='$1' AND table_type='BASE TABLE' ORDER BY table_name"
}
original=$(list_tables "$MYSQL_DATABASE")
restored=$(list_tables "$tmp_db")
[[ -n $original ]]
printf '%-20s %10s %10s  %s\n' TABLE ORIGINAL RESTORED RESULT
result=0
mapfile -t tables <<< "$original"
for table in "${tables[@]}"; do
    [[ $table =~ ^[a-zA-Z0-9_]+$ ]]
    a=$(db primary -NB "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM \`$table\`")
    if [[ $'\n'$restored$'\n' == *$'\n'"$table"$'\n'* ]]; then
        b=$(db primary -NB "$tmp_db" -e "SELECT COUNT(*) FROM \`$table\`")
    else
        b=missing
    fi
    if [[ $a == "$b" ]]; then state=OK; else state=MISMATCH; result=1; fi
    printf '%-20s %10s %10s  %s\n' "$table" "$a" "$b" "$state"
done
if [[ $original != "$restored" ]]; then
    printf 'MISMATCH: набори таблиць відрізняються.\n' >&2
    result=1
fi
if (( result == 0 )); then printf 'Копія придатна до відновлення.\n'; fi
exit "$result"

#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
umask 077
mkdir -p "$BACKUP_DIR"
stamp=$(date -u +%F_%H%M%S)
tmp=$(mktemp "$BACKUP_DIR/.dump.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
file="$BACKUP_DIR/${MYSQL_DATABASE}_${stamp}_${tmp##*.}.sql.gz"

docker compose exec -T primary sh -c '
    export MYSQL_PWD="$BACKUP_PASSWORD"
    exec mysqldump -ubackup_user --default-character-set=utf8mb4 --single-transaction \
        --routines --triggers --events --source-data=2 --set-gtid-purged=OFF \
        --no-tablespaces "$1"
' sh "$MYSQL_DATABASE" | gzip > "$tmp"
gzip -t "$tmp"
mv -- "$tmp" "$file"
printf 'OK: %s (%s)\n' "$file" "$(du -h "$file" | cut -f1)" >&2
find "$BACKUP_DIR" -maxdepth 1 -type f -name "${MYSQL_DATABASE}_*.sql.gz" \
    -mmin "+$((KEEP_DAYS * 1440))" -print -delete >&2
printf '%s\n' "$file"

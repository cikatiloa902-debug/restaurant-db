#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
docker compose ps
for service in primary replica; do
    printf '\n%s\n' "$service"
    db "$service" -e 'SELECT VERSION() AS version, @@server_id, @@gtid_mode, @@read_only;'
done
db primary restaurant_db -e 'SHOW TABLES'

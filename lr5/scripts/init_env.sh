#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
if [[ -e .env ]]; then
    printf '.env вже існує. Використайте його для поточного стенду.\n'
    exit 0
fi
umask 077
while IFS='=' read -r name value; do
    case "$value" in
        REPLACE_ME_*) value=$(od -An -N24 -tx1 /dev/urandom | tr -d '[:space:]');;
    esac
    printf '%s=%s\n' "$name" "$value"
done < .env.example > .env
printf 'Створено локальний .env.\n'

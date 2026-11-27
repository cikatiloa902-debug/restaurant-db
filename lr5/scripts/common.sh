# Спільні параметри лабораторного стенду.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'
source ./.env

for key in MYSQL_ROOT_PASSWORD APP_PASSWORD REPORT_PASSWORD BACKUP_PASSWORD REPL_PASSWORD VIEWER_PASSWORD; do
    if ! [[ ${!key} =~ ^[[:xdigit:]]{48}$ ]]; then
        printf 'Очікується згенерований пароль у %s. Див. README.md.\n' "$key" >&2
        exit 1
    fi
done
# CHANGE REPLICATION SOURCE TO приймає пароль до 32 символів.
REPL_PASSWORD=${REPL_PASSWORD:0:32}
[[ $MYSQL_DATABASE == restaurant_db && $BACKUP_USER == backup_user ]]
BACKUP_DIR=backups
KEEP_DAYS=${KEEP_DAYS:-7}
[[ $KEEP_DAYS =~ ^[0-9]+$ ]]

db() {
    local service=$1
    shift
    docker compose exec -T "$service" sh -c '
        export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
        exec mysql -uroot --default-character-set=utf8mb4 "$@"
    ' sh "$@"
}

as_user() {
    local service=$1 user=$2
    shift 2
    MYSQL_PWD=$LAB_PASSWORD docker compose exec -T -e MYSQL_PWD "$service" \
        mysql -u "$user" --default-character-set=utf8mb4 "$@"
}

expect_error() {
    local pattern=$1 result
    shift
    if result=$("$@" 2>&1); then
        printf 'Очікувалася відмова, але команда виконалася.\n' >&2
        return 1
    fi
    printf '%s\n' "$result"
    [[ $result == *"$pattern"* ]]
}

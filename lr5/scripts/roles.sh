#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

sed -e "s/@APP_PASSWORD@/$APP_PASSWORD/g" -e "s/@REPORT_PASSWORD@/$REPORT_PASSWORD/g" \
    -e "s/@BACKUP_PASSWORD@/$BACKUP_PASSWORD/g" -e "s/@REPL_PASSWORD@/$REPL_PASSWORD/g" \
    sql/01_users.sql | db primary

db primary <<'SQL'
SHOW GRANTS FOR 'app_user'@'%' USING 'app_rw';
SHOW GRANTS FOR 'report_user'@'%' USING 'reporting_ro';
SHOW GRANTS FOR 'backup_user'@'localhost';
SHOW GRANTS FOR 'repl'@'%';
CREATE TABLE IF NOT EXISTS restaurant_db.lr5_privilege_probe (id INT PRIMARY KEY) ENGINE=InnoDB;
SQL

LAB_PASSWORD=$APP_PASSWORD
as_user primary app_user restaurant_db <<'SQL'
SELECT name, price FROM food ORDER BY food_id LIMIT 3;
START TRANSACTION;
UPDATE food SET price = price + 1 WHERE food_id = 1;
SELECT ROW_COUNT() AS updated_rows;
ROLLBACK;
SQL
expect_error 'ERROR 1142' as_user primary app_user restaurant_db -e 'DROP TABLE lr5_privilege_probe'
expect_error 'ERROR 1142' as_user primary app_user -e 'SELECT user FROM mysql.user'

LAB_PASSWORD=$REPORT_PASSWORD
as_user primary report_user restaurant_db -e 'SELECT COUNT(*) AS foods FROM food'
expect_error 'ERROR 1142' as_user primary report_user restaurant_db -e 'DELETE FROM lr5_privilege_probe WHERE id=1'

unlock() { db primary -e "ALTER USER 'app_user'@'%' ACCOUNT UNLOCK" >/dev/null; }
trap unlock EXIT
LAB_PASSWORD=WrongPasswordForLocalLab
for attempt in 1 2 3; do
    output=$(as_user primary app_user -e 'SELECT 1' 2>&1) && exit 1
    printf 'Спроба %s: %s\n' "$attempt" "$output"
    [[ $output == *'ERROR 1045'* || $output == *'ERROR 3955'* ]]
done
LAB_PASSWORD=$APP_PASSWORD
expect_error 'ERROR 3955' as_user primary app_user -e 'SELECT 1'
unlock
trap - EXIT
as_user primary app_user -e 'SELECT CURRENT_USER() AS unlocked_account'

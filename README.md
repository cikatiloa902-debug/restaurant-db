# Інформаційна система ресторану — ЛР2
Мазеїна Марина Олегівна та Опімах Андрій Володимирович, КІ-251.

Репозиторій: https://github.com/cikatiloa902-debug/restaurant-db
ER-модель ЛР1: https://dbdiagram.io/d/LR-%E2%84%961-Mazeyina-M-O-ta-Opimah-A-V-KI-251-6abb87400f25a52d013b4c4a

## Файли
- `mysql/init/01_schema.sql` — 10 таблиць, первинні та зовнішні ключі, UNIQUE та CHECK.
- `mysql/init/02_data.sql` — вигадані тестові дані (35 записів).
- `03_queries.sql` — вибірки з кожної таблиці та перевірка зв'язків.
- `docker-compose.yml` — MySQL 8.4; локальний порт 3307.
- `.env.example` — приклад локальних налаштувань; скопіювати в `.env`.
- `.github/workflows/mysql-check.yml` — виконання в MySQL через GitHub Actions і створення справжнього дампа.

## Статус перевірки
Базу даних restaurant_db успішно створено та перевірено в MySQL 8.4 через GitHub Actions. Запуск №6 завершився успішно. База містить 10 таблиць і 35 тестових записів. Дамп restaurant_db_dump.sql та звіт LR2_Mazeina_KI251.docx зі скриншотами результатів додано до репозиторію.

Логіку семи некоректних вставок додатково перевірено на адаптованій моделі у SQLite.
## Запуск у Docker Desktop (PowerShell)
Відкрити термінал у папці проєкту:
```powershell
Copy-Item .env.example .env
# За бажанням змінити локальні навчальні паролі у .env.
docker compose up -d --wait
docker compose exec mysql sh -c 'mysql --default-character-set=utf8mb4 -uroot -p"$MYSQL_ROOT_PASSWORD" restaurant_db'
```
У відкритому клієнті MySQL:
```sql
SHOW TABLES;
DESCRIBE `order_item`;
SELECT * FROM `food` LIMIT 5;
SELECT * FROM `order_item` LIMIT 5;
```
Запити з `03_queries.sql` можна копіювати у клієнт. Після запитів ввести `exit`.

## Експорт дампа (PowerShell)
Після успішного запуску:
```powershell
docker compose exec mysql sh -c 'mysqldump --default-character-set=utf8mb4 --no-tablespaces -uroot -p"$MYSQL_ROOT_PASSWORD" restaurant_db > /tmp/restaurant_db_dump.sql'
docker compose cp mysql:/tmp/restaurant_db_dump.sql ./restaurant_db_dump.sql
```
Додати справжній отриманий дамп до GitHub і до матеріалів ЛР2.

## Перевірка через GitHub Actions

Базу даних перевірено в MySQL 8.4 через GitHub Actions за допомогою workflow `.github/workflows/mysql-check.yml`.

Під час перевірки створено таблиці, завантажено тестові дані, виконано запити з `03_queries.sql` та експортовано дамп. Запуск №6 завершився успішно.

Результати запитів і дамп доступні в артефакті `restaurant-db-results` відповідного успішного запуску у вкладці Actions. Файл `restaurant_db_dump.sql` та звіт `LR2_Mazeina_KI251.docx` зі скриншотами також додано до репозиторію.

## Особливості реалізації
Назви `order`, `user`, `transaction` екрановано зворотними лапками. Для грошей — DECIMAL(10,2), для ключів — INT AUTO_INCREMENT. Поле password розширено до VARCHAR(255) для хешу; тестові значення є заглушками, не паролями та не справжніми хешами.

У order_item та chef_specialty має бути рівно один food_id або drink_id. chef_id і reservation_id у позиції необов'язкові. UNIQUE(order_id) у notification і transaction реалізує «не більше одного запису на замовлення»; наявність повідомлення чи оплати для кожного замовлення не гарантується.

Схема відповідає наданим 10 сутностям; ролей користувачів у вихідному DBML немає. Кількість та історична ціна позиції, час бронювання і перевірка доступності столика потребують окремого розширення. Поточні запити підсумовують ціни меню, які можуть змінюватися. Зв'язок chef_specialty описує вміння кухаря, order_item.chef_id — фактичного виконавця. Відповідність виконавця спеціалізації перевіряється окремим запитом; зовнішні ключі її не гарантують. Належність бронювання та замовлення тому самому клієнтові також є правилом для прикладного коду або окремої перевірки.

## Повторний запуск
Ініціалізація виконується тільки для нового порожнього тому. Зміни SQL-файлів не застосовуються автоматично до вже створеної бази. Звичайна зупинка `docker compose down` зберігає дані. Скрипти не передбачають повторної вставки тестових даних у заповнену базу.

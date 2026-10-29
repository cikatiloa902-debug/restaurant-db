SET NAMES utf8mb4;
USE restaurant_db_lr3;
-- Кількість рядків у всіх 10 таблицях.
SELECT 'user' AS table_name, COUNT(*) AS row_count FROM `user`
UNION ALL
SELECT 'food' AS table_name, COUNT(*) AS row_count FROM `food`
UNION ALL
SELECT 'drink' AS table_name, COUNT(*) AS row_count FROM `drink`
UNION ALL
SELECT 'chef' AS table_name, COUNT(*) AS row_count FROM `chef`
UNION ALL
SELECT 'reservation' AS table_name, COUNT(*) AS row_count FROM `reservation`
UNION ALL
SELECT 'order' AS table_name, COUNT(*) AS row_count FROM `order`
UNION ALL
SELECT 'order_item' AS table_name, COUNT(*) AS row_count FROM `order_item`
UNION ALL
SELECT 'chef_specialty' AS table_name, COUNT(*) AS row_count FROM `chef_specialty`
UNION ALL
SELECT 'notification' AS table_name, COUNT(*) AS row_count FROM `notification`
UNION ALL
SELECT 'transaction' AS table_name, COUNT(*) AS row_count FROM `transaction`;

-- Усі зовнішні ключі та індекси, що починаються з поля FK.
SELECT k.TABLE_NAME, k.COLUMN_NAME, k.REFERENCED_TABLE_NAME,
       k.REFERENCED_COLUMN_NAME,
       EXISTS (SELECT 1 FROM information_schema.STATISTICS s
               WHERE s.TABLE_SCHEMA = k.TABLE_SCHEMA
                 AND s.TABLE_NAME = k.TABLE_NAME
                 AND s.COLUMN_NAME = k.COLUMN_NAME AND s.SEQ_IN_INDEX = 1) AS indexed
FROM information_schema.KEY_COLUMN_USAGE k
WHERE k.TABLE_SCHEMA = DATABASE() AND k.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY k.TABLE_NAME, k.COLUMN_NAME;

-- Типи FK та відповідних первинних ключів.
SELECT k.TABLE_NAME, k.COLUMN_NAME, c.COLUMN_TYPE AS fk_type,
       p.COLUMN_TYPE AS referenced_type,
       c.COLUMN_TYPE = p.COLUMN_TYPE AS types_match
FROM information_schema.KEY_COLUMN_USAGE k
JOIN information_schema.COLUMNS c
  ON c.TABLE_SCHEMA = k.TABLE_SCHEMA AND c.TABLE_NAME = k.TABLE_NAME
 AND c.COLUMN_NAME = k.COLUMN_NAME
JOIN information_schema.COLUMNS p
  ON p.TABLE_SCHEMA = k.REFERENCED_TABLE_SCHEMA
 AND p.TABLE_NAME = k.REFERENCED_TABLE_NAME AND p.COLUMN_NAME = k.REFERENCED_COLUMN_NAME
WHERE k.TABLE_SCHEMA = DATABASE() AND k.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY k.TABLE_NAME, k.COLUMN_NAME;

-- Позиції з двома продуктами або без продукту.
SELECT COUNT(*) AS invalid_product_rows
FROM order_item WHERE (food_id IS NULL) = (drink_id IS NULL);

-- Кухар без потрібної спеціалізації.
SELECT COUNT(*) AS chef_mismatches
FROM order_item oi
WHERE oi.chef_id IS NOT NULL AND NOT EXISTS (
 SELECT 1 FROM chef_specialty cs WHERE cs.chef_id=oi.chef_id
 AND (cs.food_id=oi.food_id OR cs.drink_id=oi.drink_id)
);

-- Бронювання та замовлення різних клієнтів.
SELECT COUNT(*) AS reservation_user_mismatches
FROM order_item oi
JOIN `order` o ON o.order_id=oi.order_id
JOIN reservation r ON r.reservation_id=oi.reservation_id
WHERE o.user_id <> r.user_id;

-- Оплати, що відрізняються від суми поточних цін меню.
SELECT COUNT(*) AS payment_mismatches
FROM `transaction` t
JOIN (
 SELECT oi.order_id, SUM(COALESCE(f.price,d.price)) AS total
 FROM order_item oi
 LEFT JOIN food f ON f.food_id=oi.food_id
 LEFT JOIN drink d ON d.drink_id=oi.drink_id
 GROUP BY oi.order_id
) x ON x.order_id=t.order_id
WHERE t.amount <> x.total;

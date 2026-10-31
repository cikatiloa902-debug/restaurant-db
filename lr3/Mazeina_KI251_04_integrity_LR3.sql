SET NAMES utf8mb4;
USE restaurant_db;

-- Кількість записів у кожній таблиці.
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

-- Усі FK, сумісність типів і наявність індексу, який починається з FK.
SELECT k.TABLE_NAME, k.COLUMN_NAME, k.REFERENCED_TABLE_NAME,
       c.COLUMN_TYPE AS fk_type, p.COLUMN_TYPE AS pk_type,
       c.COLUMN_TYPE = p.COLUMN_TYPE AS types_match,
       EXISTS (
           SELECT 1 FROM information_schema.STATISTICS AS s
           WHERE s.TABLE_SCHEMA = k.TABLE_SCHEMA
             AND s.TABLE_NAME = k.TABLE_NAME
             AND s.COLUMN_NAME = k.COLUMN_NAME
             AND s.SEQ_IN_INDEX = 1
       ) AS fk_index_exists
FROM information_schema.KEY_COLUMN_USAGE AS k
JOIN information_schema.COLUMNS AS c
  ON c.TABLE_SCHEMA = k.TABLE_SCHEMA
 AND c.TABLE_NAME = k.TABLE_NAME AND c.COLUMN_NAME = k.COLUMN_NAME
JOIN information_schema.COLUMNS AS p
  ON p.TABLE_SCHEMA = k.REFERENCED_TABLE_SCHEMA
 AND p.TABLE_NAME = k.REFERENCED_TABLE_NAME
 AND p.COLUMN_NAME = k.REFERENCED_COLUMN_NAME
WHERE k.TABLE_SCHEMA = DATABASE()
  AND k.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY k.TABLE_NAME, k.COLUMN_NAME;

-- Реальний перелік індексів зв’язувальної таблиці.
SHOW INDEX FROM order_item;

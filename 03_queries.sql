-- Запити для перевірки та скриншотів
USE `restaurant_db`;
SHOW TABLES;
DESCRIBE `order_item`;
SHOW CREATE TABLE `transaction`;

SELECT * FROM `user` LIMIT 5;
SELECT * FROM `food` LIMIT 5;
SELECT * FROM `drink` LIMIT 5;
SELECT * FROM `chef` LIMIT 5;
SELECT * FROM `reservation` LIMIT 5;
SELECT * FROM `order` LIMIT 5;
SELECT * FROM `order_item` LIMIT 5;
SELECT * FROM `chef_specialty` LIMIT 5;
SELECT * FROM `notification` LIMIT 5;
SELECT * FROM `transaction` LIMIT 5;

-- Позиції замовлень: клієнт, страва/напій та фактичний виконавець.
SELECT o.order_id, CONCAT(u.first_name, ' ', u.last_name) AS customer,
       COALESCE(f.name, d.name) AS item_name,
       COALESCE(f.price, d.price) AS current_menu_price,
       c.name AS chef, o.order_status
FROM `order_item` oi
JOIN `order` o ON o.order_id = oi.order_id
JOIN `user` u ON u.user_id = o.user_id
LEFT JOIN `food` f ON f.food_id = oi.food_id
LEFT JOIN `drink` d ON d.drink_id = oi.drink_id
LEFT JOIN `chef` c ON c.chef_id = oi.chef_id
ORDER BY o.order_id, oi.order_item_id;

-- Вартість за поточними цінами меню, а не історична сума замовлення.
SELECT oi.order_id, SUM(COALESCE(f.price,d.price)) AS current_menu_total
FROM `order_item` oi
LEFT JOIN `food` f ON f.food_id = oi.food_id
LEFT JOIN `drink` d ON d.drink_id = oi.drink_id
GROUP BY oi.order_id ORDER BY oi.order_id;

-- Бронювання клієнтів.
SELECT r.reservation_id, u.first_name, u.last_name,
       r.reserved_date, r.table_number
FROM `reservation` r JOIN `user` u ON u.user_id = r.user_id
ORDER BY r.reserved_date, r.table_number;

-- Контроль виконавців: очікується 0 рядків для цих тестових даних.
SELECT oi.order_item_id, oi.chef_id
FROM `order_item` oi
LEFT JOIN `chef_specialty` cs ON cs.chef_id = oi.chef_id
 AND ((oi.food_id IS NOT NULL AND cs.food_id = oi.food_id)
   OR (oi.drink_id IS NOT NULL AND cs.drink_id = oi.drink_id))
WHERE oi.chef_id IS NOT NULL AND cs.chef_specialty_id IS NULL;

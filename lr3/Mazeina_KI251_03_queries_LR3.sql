SET NAMES utf8mb4;
USE restaurant_db;

-- Q01. Усі страви меню
SELECT * FROM food ORDER BY food_id;

-- Q02. Назви та ціни напоїв
SELECT name, price FROM drink ORDER BY drink_id;

-- Q03. Страви дорожчі за 120 грн
SELECT food_id, name, price
FROM food
WHERE price > 120
ORDER BY price, food_id;

-- Q04. Страви ціною від 90 до 180 грн
SELECT food_id, name, price
FROM food
WHERE price >= 90 AND price <= 180
ORDER BY price DESC, food_id;

-- Q05. Три найдорожчі страви
SELECT food_id, name, price
FROM food
ORDER BY price DESC, food_id
LIMIT 3;

-- Q06. Замовлення та їх клієнти
SELECT o.order_id, u.first_name, u.last_name, o.order_status
FROM `order` AS o
JOIN `user` AS u ON u.user_id = o.user_id
ORDER BY o.order_id;

-- Q07. Замовлення із сумою меню понад 200 грн
SELECT oi.order_id, SUM(COALESCE(f.price, d.price)) AS menu_total
FROM order_item AS oi
LEFT JOIN food AS f ON f.food_id = oi.food_id
LEFT JOIN drink AS d ON d.drink_id = oi.drink_id
GROUP BY oi.order_id
HAVING SUM(COALESCE(f.price, d.price)) > 200
ORDER BY menu_total DESC, oi.order_id;

-- Q08. Клієнти з оплаченими замовленнями
SELECT u.user_id, u.first_name, u.last_name
FROM `user` AS u
WHERE u.user_id IN (
    SELECT o.user_id
    FROM `order` AS o
    JOIN `transaction` AS t ON t.order_id = o.order_id
)
ORDER BY u.user_id;

-- Q09. Клієнти, які мають бронювання
SELECT u.user_id, u.first_name, u.last_name
FROM `user` AS u
WHERE EXISTS (
    SELECT 1 FROM reservation AS r
    WHERE r.user_id = u.user_id
)
ORDER BY u.user_id;

-- Q10. Страви дорожчі хоча б за один напій
SELECT food_id, name, price
FROM food
WHERE price > ANY (SELECT price FROM drink)
ORDER BY price, food_id;

-- Q11. Страви дорожчі за кожний напій
SELECT food_id, name, price
FROM food
WHERE price > ALL (SELECT price FROM drink)
ORDER BY price, food_id;

-- Q12. Замовлення без зареєстрованої оплати
SELECT o.order_id, o.order_status
FROM `order` AS o
WHERE NOT EXISTS (
    SELECT 1 FROM `transaction` AS t
    WHERE t.order_id = o.order_id
)
ORDER BY o.order_id;

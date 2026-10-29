SET NAMES utf8mb4;
USE restaurant_db_lr3;

-- Q01: Усі страви меню
-- Проста вибірка всіх страв із впорядкуванням за ідентифікатором.
SELECT food_id, name, description, price
FROM food
ORDER BY food_id;

-- Q02: Контактні дані клієнтів
-- Вибір потрібних полів без виведення поля password.
SELECT user_id, first_name, last_name, email
FROM `user`
ORDER BY last_name, first_name;

-- Q03: Страви за заданою ціною
-- Фільтрація страв вартістю від 100 до 200 грн.
SELECT name, price
FROM food
WHERE price BETWEEN 100 AND 200
ORDER BY price, name;

-- Q04: Бронювання за період
-- Поєднання умови для дат і сортування.
SELECT reservation_id, user_id, reserved_date, table_number
FROM reservation
WHERE reserved_date BETWEEN '2026-10-10' AND '2026-10-16'
ORDER BY reserved_date DESC, table_number;

-- Q05: Три найдорожчі напої
-- Сортування за спаданням та обмеження LIMIT.
SELECT drink_id, name, price
FROM drink
ORDER BY price DESC, drink_id
LIMIT 3;

-- Q06: Замовлення та їхні клієнти
-- JOIN двох таблиць; показ перших десяти замовлень.
SELECT o.order_id, CONCAT(u.first_name, ' ', u.last_name) AS customer,
       o.order_status
FROM `order` o
JOIN `user` u ON u.user_id = o.user_id
ORDER BY o.order_id
LIMIT 10;

-- Q07: Суми замовлень від 300 грн
-- Агрегація GROUP BY, умова HAVING; суми за поточними цінами меню.
SELECT oi.order_id, SUM(COALESCE(f.price, d.price)) AS menu_total
FROM order_item oi
LEFT JOIN food f ON f.food_id = oi.food_id
LEFT JOIN drink d ON d.drink_id = oi.drink_id
GROUP BY oi.order_id
HAVING SUM(COALESCE(f.price, d.price)) >= 300
ORDER BY menu_total DESC, oi.order_id;

-- Q08: Кількість позицій за кухарями
-- LEFT JOIN зберігає кухарів без призначених позицій; COUNT рахує лише наявні позиції.
SELECT c.chef_id, c.name, COUNT(oi.order_item_id) AS item_count
FROM chef c
LEFT JOIN order_item oi ON oi.chef_id = c.chef_id
GROUP BY c.chef_id, c.name
ORDER BY item_count DESC, c.chef_id;

-- Q09: Клієнти із завершеними замовленнями
-- Підзапит IN повертає клієнтів із хоча б одним completed-замовленням.
SELECT user_id, first_name, last_name
FROM `user`
WHERE user_id IN (
    SELECT user_id FROM `order` WHERE order_status = 'completed'
)
ORDER BY user_id;

-- Q10: Клієнти з бронюваннями
-- Корельований EXISTS перевіряє наявність бронювання для кожного клієнта.
SELECT u.user_id, u.first_name, u.last_name
FROM `user` u
WHERE EXISTS (
    SELECT 1 FROM reservation r WHERE r.user_id = u.user_id
)
ORDER BY u.user_id;

-- Q11: Клієнти без замовлень
-- Корельований NOT EXISTS знаходить клієнтів, які ще не зробили замовлення.
SELECT u.user_id, u.first_name, u.last_name
FROM `user` u
WHERE NOT EXISTS (
    SELECT 1 FROM `order` o WHERE o.user_id = u.user_id
)
ORDER BY u.user_id;

-- Q12: Страви дорожчі за хоча б один напій
-- Явний ANY: ціна страви перевищує принаймні одне значення з підзапиту.
SELECT food_id, name, price
FROM food
WHERE price > ANY (SELECT price FROM drink)
ORDER BY price, food_id;

-- Q13: Страви дорожчі за всі напої
-- Явний ALL: ціна страви перевищує кожну ціну напою.
SELECT food_id, name, price
FROM food
WHERE price > ALL (SELECT price FROM drink)
ORDER BY price, food_id;

-- Q14: Страви дорожчі за середню ціну
-- Скалярний підзапит з AVG визначає поріг для порівняння.
SELECT food_id, name, price
FROM food
WHERE price > (SELECT AVG(price) FROM food)
ORDER BY price DESC, food_id;

-- Q15: Клієнти з двома або більше замовленнями
-- Корельований підзапит COUNT для кожного клієнта.
SELECT u.user_id, u.first_name, u.last_name
FROM `user` u
WHERE (SELECT COUNT(*) FROM `order` o WHERE o.user_id = u.user_id) >= 2
ORDER BY u.user_id;

-- Q16: Замовлення без оплати
-- Корельований NOT EXISTS для перевірки відсутності оплати.
SELECT o.order_id, o.order_status
FROM `order` o
WHERE NOT EXISTS (
    SELECT 1 FROM `transaction` t WHERE t.order_id = o.order_id
)
ORDER BY o.order_id;

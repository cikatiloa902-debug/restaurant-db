SET NAMES utf8mb4;
-- ЛР3. Інформаційна система ресторану. MySQL 8.4
-- Мазеїна М. О. та Опімах А. В., КІ-251
-- Виконувати у новій порожній базі; скрипт не видаляє наявні таблиці.
CREATE DATABASE IF NOT EXISTS `restaurant_db_lr3` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `restaurant_db_lr3`;

CREATE TABLE `user` (
  `user_id` INT NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(50) NOT NULL,
  `last_name` VARCHAR(50) NOT NULL,
  `email` VARCHAR(100) NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `food` (
  `food_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(150),
  `price` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`food_id`),
  CHECK (`price` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `drink` (
  `drink_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(150),
  `price` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`drink_id`),
  CHECK (`price` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `chef` (
  `chef_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  `specialization` VARCHAR(50),
  PRIMARY KEY (`chef_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `reservation` (
  `reservation_id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT NOT NULL,
  `reserved_date` DATE NOT NULL,
  `table_number` INT NOT NULL,
  PRIMARY KEY (`reservation_id`),
  CHECK (`table_number` > 0),
  FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order` (
  `order_id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT NOT NULL,
  `order_status` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`order_id`),
  FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_item` (
  `order_item_id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `food_id` INT,
  `drink_id` INT,
  `reservation_id` INT,
  `chef_id` INT,
  PRIMARY KEY (`order_item_id`),
  CHECK ((`food_id` IS NOT NULL AND `drink_id` IS NULL) OR (`food_id` IS NULL AND `drink_id` IS NOT NULL)),
  FOREIGN KEY (`order_id`) REFERENCES `order` (`order_id`),
  FOREIGN KEY (`food_id`) REFERENCES `food` (`food_id`),
  FOREIGN KEY (`drink_id`) REFERENCES `drink` (`drink_id`),
  FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`),
  FOREIGN KEY (`chef_id`) REFERENCES `chef` (`chef_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `chef_specialty` (
  `chef_specialty_id` INT NOT NULL AUTO_INCREMENT,
  `chef_id` INT NOT NULL,
  `food_id` INT,
  `drink_id` INT,
  PRIMARY KEY (`chef_specialty_id`),
  UNIQUE (`chef_id`, `food_id`),
  UNIQUE (`chef_id`, `drink_id`),
  CHECK ((`food_id` IS NOT NULL AND `drink_id` IS NULL) OR (`food_id` IS NULL AND `drink_id` IS NOT NULL)),
  FOREIGN KEY (`chef_id`) REFERENCES `chef` (`chef_id`),
  FOREIGN KEY (`food_id`) REFERENCES `food` (`food_id`),
  FOREIGN KEY (`drink_id`) REFERENCES `drink` (`drink_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notification` (
  `notification_id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `message` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`notification_id`),
  UNIQUE (`order_id`),
  FOREIGN KEY (`order_id`) REFERENCES `order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `transaction` (
  `transaction_id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `transaction_date` DATE NOT NULL,
  PRIMARY KEY (`transaction_id`),
  UNIQUE (`order_id`),
  CHECK (`amount` >= 0),
  FOREIGN KEY (`order_id`) REFERENCES `order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ЛР3. Повний набір тестових даних для окремої порожньої БД.
-- Усі імена та адреси вигадані. Повторно не імпортувати в заповнену БД.
SET NAMES utf8mb4;
USE restaurant_db_lr3;
START TRANSACTION;

INSERT INTO `user` (`user_id`,`first_name`,`last_name`,`email`,`password`) VALUES
  (1, 'Олена', 'Коваль', 'olena@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
  (2, 'Ірина', 'Бондар', 'iryna@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
  (3, 'Марія', 'Мельник', 'maria@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
  (4, 'Андрій', 'Шевченко', 'andrii@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
  (5, 'Богдан', 'Ткаченко', 'bohdan@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
  (6, 'Софія', 'Кравченко', 'sofia@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
  (7, 'Максим', 'Олійник', 'maksym@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
  (8, 'Юлія', 'Савченко', 'yuliia@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
  (9, 'Дмитро', 'Лисенко', 'dmytro@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
  (10, 'Катерина', 'Романенко', 'kateryna@example.test', 'DEMO_HASH_NOT_FOR_LOGIN');

INSERT INTO `food` (`food_id`,`name`,`description`,`price`) VALUES
  (1, 'Борщ', 'Борщ зі сметаною', 95),
  (2, 'Салат', 'Овочевий салат', 80),
  (3, 'Вареники', 'Вареники з картоплею', 110),
  (4, 'Куряче філе', 'Запечене філе з овочами', 180),
  (5, 'Деруни', 'Деруни зі сметаною', 125),
  (6, 'Сирники', 'Сирники з ягідним соусом', 135),
  (7, 'Стейк', 'Яловичий стейк', 340),
  (8, 'Паста', 'Паста з куркою та грибами', 195),
  (9, 'Риба', 'Запечене філе судака', 260),
  (10, 'Чизкейк', 'Десерт із вершкового сиру', 145);

INSERT INTO `drink` (`drink_id`,`name`,`description`,`price`) VALUES
  (1, 'Чай', 'Чорний чай', 35),
  (2, 'Кава', 'Американо', 45),
  (3, 'Узвар', 'Напій із сухофруктів', 40),
  (4, 'Лате', 'Кава з молоком', 65),
  (5, 'Лимонад', 'Домашній цитрусовий лимонад', 130),
  (6, 'Морс', 'Журавлинний морс', 55),
  (7, 'Какао', 'Гарячий шоколадний напій', 60),
  (8, 'Вода', 'Негазована вода', 30),
  (9, 'Сік', 'Яблучний сік', 50),
  (10, 'Еспресо', 'Міцна чорна кава', 40);

INSERT INTO `chef` (`chef_id`,`name`,`specialization`) VALUES
  (1, 'Олег', 'Перші страви та напої'),
  (2, 'Наталія', 'Салати та другі страви'),
  (3, 'Іван', 'М’ясні страви'),
  (4, 'Оксана', 'Десерти'),
  (5, 'Петро', 'Рибні страви'),
  (6, 'Ольга', 'Українська кухня'),
  (7, 'Тарас', 'Італійська кухня'),
  (8, 'Ганна', 'Холодні закуски'),
  (9, 'Роман', 'Напої та десерти'),
  (10, 'Вікторія', 'Вегетаріанські страви');

INSERT INTO `reservation` (`reservation_id`,`user_id`,`reserved_date`,`table_number`) VALUES
  (1, 1, '2026-10-10', 1),
  (2, 2, '2026-10-10', 2),
  (3, 1, '2026-10-11', 3),
  (4, 2, '2026-10-12', 4),
  (5, 3, '2026-10-13', 5),
  (6, 4, '2026-10-14', 6),
  (7, 5, '2026-10-15', 7),
  (8, 6, '2026-10-16', 8),
  (9, 7, '2026-10-17', 9),
  (10, 8, '2026-10-18', 10),
  (11, 9, '2026-10-19', 11),
  (12, 10, '2026-10-20', 12);

INSERT INTO `order` (`order_id`,`user_id`,`order_status`) VALUES
  (1, 1, 'completed'),
  (2, 2, 'preparing'),
  (3, 1, 'new'),
  (4, 3, 'completed'),
  (5, 4, 'completed'),
  (6, 5, 'ready'),
  (7, 6, 'completed'),
  (8, 7, 'completed'),
  (9, 1, 'completed'),
  (10, 2, 'completed'),
  (11, 3, 'completed'),
  (12, 4, 'completed'),
  (13, 5, 'completed'),
  (14, 6, 'preparing'),
  (15, 7, 'ready'),
  (16, 1, 'new'),
  (17, 2, 'cancelled'),
  (18, 3, 'preparing'),
  (19, 4, 'ready'),
  (20, 5, 'new');

INSERT INTO `order_item` (`order_item_id`,`order_id`,`food_id`,`drink_id`,`reservation_id`,`chef_id`) VALUES
  (1, 1, 1, NULL, 1, 1),
  (2, 1, 2, NULL, 1, 2),
  (3, 1, NULL, 1, 1, 1),
  (4, 2, 3, NULL, 2, 2),
  (5, 2, NULL, 2, 2, 1),
  (6, 3, 1, NULL, NULL, NULL),
  (7, 4, 1, NULL, 5, 1),
  (8, 4, 2, NULL, 5, 2),
  (9, 4, NULL, 1, 5, 3),
  (10, 5, 2, NULL, 6, 2),
  (11, 5, 3, NULL, 6, 3),
  (12, 5, NULL, 2, 6, 4),
  (13, 6, 3, NULL, 7, 3),
  (14, 6, 4, NULL, 7, 4),
  (15, 6, NULL, 3, 7, 5),
  (16, 7, 4, NULL, 8, 4),
  (17, 7, 5, NULL, 8, 5),
  (18, 7, NULL, 4, 8, 6),
  (19, 8, 5, NULL, 9, 5),
  (20, 8, 6, NULL, 9, 6),
  (21, 8, NULL, 5, 9, 7),
  (22, 9, 6, NULL, 1, 6),
  (23, 9, 7, NULL, 1, 7),
  (24, 9, NULL, 6, 1, 8),
  (25, 10, 7, NULL, 2, 7),
  (26, 10, 8, NULL, 2, 8),
  (27, 10, NULL, 7, 2, 9),
  (28, 11, 8, NULL, 5, 8),
  (29, 11, 9, NULL, 5, 9),
  (30, 11, NULL, 8, 5, 10),
  (31, 12, 9, NULL, 6, 9),
  (32, 12, 10, NULL, 6, 10),
  (33, 12, NULL, 9, 6, 1),
  (34, 13, 10, NULL, 7, 10),
  (35, 13, 1, NULL, 7, 1),
  (36, 13, NULL, 10, 7, 2),
  (37, 14, 1, NULL, 8, 1),
  (38, 14, 2, NULL, 8, 2),
  (39, 14, NULL, 1, 8, 3),
  (40, 15, 2, NULL, 9, 2),
  (41, 15, 3, NULL, 9, 3),
  (42, 15, NULL, 2, 9, 4),
  (43, 16, 3, NULL, 1, 3),
  (44, 16, 4, NULL, 1, 4),
  (45, 16, NULL, 3, 1, 5),
  (46, 17, 4, NULL, 2, 4),
  (47, 17, 5, NULL, 2, 5),
  (48, 17, NULL, 4, 2, 6),
  (49, 18, 5, NULL, 5, 5),
  (50, 18, 6, NULL, 5, 6),
  (51, 18, NULL, 5, 5, 7),
  (52, 19, 6, NULL, 6, 6),
  (53, 19, 7, NULL, 6, 7),
  (54, 19, NULL, 6, 6, 8),
  (55, 20, 7, NULL, 7, 7),
  (56, 20, 8, NULL, 7, 8),
  (57, 20, NULL, 7, 7, 9);

INSERT INTO `chef_specialty` (`chef_specialty_id`,`chef_id`,`food_id`,`drink_id`) VALUES
  (1, 1, 1, NULL),
  (2, 1, NULL, 1),
  (3, 1, NULL, 2),
  (4, 1, NULL, 3),
  (5, 2, 2, NULL),
  (6, 2, 3, NULL),
  (7, 2, 1, NULL),
  (8, 3, NULL, 1),
  (9, 3, 3, NULL),
  (10, 4, NULL, 2),
  (11, 4, 4, NULL),
  (12, 5, NULL, 3),
  (13, 5, 5, NULL),
  (14, 6, NULL, 4),
  (15, 6, 6, NULL),
  (16, 7, NULL, 5),
  (17, 7, 7, NULL),
  (18, 8, NULL, 6),
  (19, 8, 8, NULL),
  (20, 9, NULL, 7),
  (21, 9, 9, NULL),
  (22, 10, NULL, 8),
  (23, 10, 10, NULL),
  (24, 1, NULL, 9),
  (25, 2, NULL, 10);

INSERT INTO `notification` (`notification_id`,`order_id`,`message`) VALUES
  (1, 1, 'Замовлення виконано'),
  (2, 2, 'Замовлення готується'),
  (3, 3, 'Замовлення прийнято'),
  (4, 4, 'Замовлення виконано'),
  (5, 5, 'Замовлення виконано'),
  (6, 6, 'Замовлення готове до видачі'),
  (7, 7, 'Замовлення виконано'),
  (8, 8, 'Замовлення виконано'),
  (9, 9, 'Замовлення виконано'),
  (10, 10, 'Замовлення виконано'),
  (11, 11, 'Замовлення виконано'),
  (12, 12, 'Замовлення виконано'),
  (13, 13, 'Замовлення виконано'),
  (14, 14, 'Замовлення готується'),
  (15, 15, 'Замовлення готове до видачі');

INSERT INTO `transaction` (`transaction_id`,`order_id`,`amount`,`transaction_date`) VALUES
  (1, 1, 210, '2026-10-11'),
  (2, 2, 155, '2026-10-12'),
  (3, 4, 210, '2026-10-13'),
  (4, 5, 235, '2026-10-14'),
  (5, 6, 330, '2026-10-15'),
  (6, 7, 370, '2026-10-16'),
  (7, 8, 390, '2026-10-17'),
  (8, 9, 530, '2026-10-18'),
  (9, 10, 595, '2026-10-19'),
  (10, 11, 485, '2026-10-20'),
  (11, 12, 455, '2026-10-21'),
  (12, 13, 280, '2026-10-22');

COMMIT;


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

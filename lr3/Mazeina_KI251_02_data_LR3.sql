-- ЛР3. Додаткові вигадані дані до незміненої схеми і 35 записів ЛР2.
-- Виконувати один раз у свіжому Docker-проєкті restaurant-lr3.
SET NAMES utf8mb4;
USE restaurant_db;
START TRANSACTION;

INSERT INTO `user` (`user_id`, `first_name`, `last_name`, `email`, `password`) VALUES
(4, 'Андрій', 'Лисенко', 'client4@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
(5, 'Марина', 'Савченко', 'client5@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
(6, 'Дмитро', 'Шевченко', 'client6@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
(7, 'Софія', 'Ткаченко', 'client7@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
(8, 'Богдан', 'Романенко', 'client8@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
(9, 'Юлія', 'Кравченко', 'client9@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
(10, 'Олексій', 'Петренко', 'client10@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
(11, 'Дарина', 'Мороз', 'client11@example.test', 'DEMO_HASH_NOT_FOR_LOGIN'),
(12, 'Віктор', 'Дорошенко', 'client12@example.test', 'DEMO_HASH_NOT_FOR_LOGIN');

INSERT INTO `food` (`food_id`, `name`, `description`, `price`) VALUES
(4, 'Деруни', 'Зі сметаною', 85),
(5, 'Курячий суп', 'З локшиною', 90),
(6, 'Плов', 'З овочами', 120),
(7, 'Риба запечена', 'З лимоном', 180),
(8, 'Котлета по-київськи', 'З гарніром', 160),
(9, 'Сирники', 'З ягідним соусом', 100),
(10, 'Голубці', 'У томатному соусі', 130),
(11, 'Стейк', 'З печеними овочами', 320),
(12, 'Салат з лососем', 'З листям салату', 240);

INSERT INTO `drink` (`drink_id`, `name`, `description`, `price`) VALUES
(4, 'Лимонад', 'Лимон та м’ята', 60),
(5, 'Какао', 'З молоком', 55),
(6, 'Сік яблучний', 'Освітлений', 50),
(7, 'Сік вишневий', 'Без м’якоті', 65),
(8, 'Вода мінеральна', 'Негазована', 30),
(9, 'Лате', 'З молоком', 90),
(10, 'Компот', 'Ягідний', 40);

INSERT INTO `chef` (`chef_id`, `name`, `specialization`) VALUES
(3, 'Іван', 'Вареники'),
(4, 'Оксана', 'Деруни'),
(5, 'Павло', 'Супи'),
(6, 'Людмила', 'Плов'),
(7, 'Тарас', 'Рибні страви'),
(8, 'Назар', 'Котлети'),
(9, 'Анна', 'Сирники'),
(10, 'Віра', 'Голубці');

INSERT INTO `reservation` (`reservation_id`, `user_id`, `reserved_date`, `table_number`) VALUES
(4, 4, '2026-10-14', 5),
(5, 5, '2026-10-15', 6),
(6, 6, '2026-10-16', 1),
(7, 7, '2026-10-17', 2),
(8, 8, '2026-10-18', 3),
(9, 9, '2026-10-19', 4),
(10, 10, '2026-10-20', 5),
(11, 11, '2026-10-21', 6),
(12, 12, '2026-10-22', 1);

INSERT INTO `order` (`order_id`, `user_id`, `order_status`) VALUES
(4, 4, 'completed'),
(5, 5, 'completed'),
(6, 6, 'completed'),
(7, 7, 'completed'),
(8, 8, 'completed'),
(9, 9, 'completed'),
(10, 10, 'completed'),
(11, 11, 'preparing'),
(12, 12, 'new'),
(13, 1, 'cancelled'),
(14, 2, 'completed'),
(15, 3, 'new');

INSERT INTO `chef_specialty` (`chef_specialty_id`, `chef_id`, `food_id`, `drink_id`) VALUES
(8, 3, 3, NULL),
(9, 4, 4, NULL),
(10, 5, 5, NULL),
(11, 6, 6, NULL),
(12, 7, 7, NULL),
(13, 8, 8, NULL),
(14, 9, 9, NULL),
(15, 10, 10, NULL);

INSERT INTO `order_item` (`order_item_id`, `order_id`, `food_id`, `drink_id`, `reservation_id`, `chef_id`) VALUES
(7, 4, 1, NULL, 4, 1),
(8, 4, NULL, 1, 4, NULL),
(9, 5, 2, NULL, 5, 2),
(10, 5, NULL, 2, 5, NULL),
(11, 6, 3, NULL, 6, 3),
(12, 6, NULL, 3, 6, NULL),
(13, 7, 4, NULL, 7, 4),
(14, 7, NULL, 4, 7, NULL),
(15, 8, 5, NULL, 8, 5),
(16, 8, NULL, 5, 8, NULL),
(17, 9, 6, NULL, 9, 6),
(18, 9, NULL, 6, 9, NULL),
(19, 10, 7, NULL, 10, 7),
(20, 10, NULL, 7, 10, NULL),
(21, 11, 8, NULL, 11, 8),
(22, 11, NULL, 8, 11, NULL),
(23, 12, 9, NULL, 12, 9),
(24, 12, NULL, 9, 12, NULL),
(25, 13, 10, NULL, NULL, 10),
(26, 13, NULL, 10, NULL, NULL),
(27, 14, 11, NULL, NULL, NULL),
(28, 14, NULL, 1, NULL, NULL),
(29, 15, 12, NULL, NULL, NULL),
(30, 15, NULL, 2, NULL, NULL);

INSERT INTO `notification` (`notification_id`, `order_id`, `message`) VALUES
(4, 4, 'Статус замовлення 4: completed'),
(5, 5, 'Статус замовлення 5: completed'),
(6, 6, 'Статус замовлення 6: completed'),
(7, 7, 'Статус замовлення 7: completed'),
(8, 8, 'Статус замовлення 8: completed'),
(9, 9, 'Статус замовлення 9: completed'),
(10, 10, 'Статус замовлення 10: completed'),
(11, 11, 'Статус замовлення 11: preparing'),
(12, 12, 'Статус замовлення 12: new'),
(13, 13, 'Статус замовлення 13: cancelled'),
(14, 14, 'Статус замовлення 14: completed'),
(15, 15, 'Статус замовлення 15: new');

INSERT INTO `transaction` (`transaction_id`, `order_id`, `amount`, `transaction_date`) VALUES
(3, 3, 95, '2026-10-13'),
(4, 4, 130, '2026-10-14'),
(5, 5, 125, '2026-10-15'),
(6, 6, 150, '2026-10-16'),
(7, 7, 145, '2026-10-17'),
(8, 8, 145, '2026-10-18'),
(9, 9, 170, '2026-10-19'),
(10, 10, 245, '2026-10-20');

COMMIT;

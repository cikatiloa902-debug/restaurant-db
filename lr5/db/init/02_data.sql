SET NAMES utf8mb4; 
-- Вигадані тестові записи. Виконувати один раз після 01_schema.sql.
USE `restaurant_db`;
START TRANSACTION;
INSERT INTO `user` VALUES
(1,'Олена','Коваль','olena@example.test','DEMO_HASH_NOT_FOR_LOGIN'),
(2,'Ірина','Бондар','iryna@example.test','DEMO_HASH_NOT_FOR_LOGIN'),
(3,'Марія','Мельник','maria@example.test','DEMO_HASH_NOT_FOR_LOGIN');
INSERT INTO `food` VALUES
(1,'Борщ','Борщ зі сметаною',95.00),
(2,'Салат','Овочевий салат',80.00),
(3,'Вареники','Вареники з картоплею',110.00);
INSERT INTO `drink` VALUES
(1,'Чай','Чорний чай',35.00),
(2,'Кава','Американо',45.00),
(3,'Узвар','Напій із сухофруктів',40.00);
INSERT INTO `chef` VALUES
(1,'Олег','Перші страви та напої'),
(2,'Наталія','Салати та другі страви');
INSERT INTO `reservation` VALUES
(1,1,'2026-10-10',1),(2,2,'2026-10-10',2),(3,1,'2026-10-11',3);
INSERT INTO `order` VALUES
(1,1,'completed'),(2,2,'preparing'),(3,1,'new');
INSERT INTO `chef_specialty` VALUES
(1,1,1,NULL),(2,1,NULL,1),(3,1,NULL,2),
(4,1,NULL,3),(5,2,2,NULL),(6,2,3,NULL),(7,2,1,NULL);
INSERT INTO `order_item` VALUES
(1,1,1,NULL,1,1),(2,1,2,NULL,1,2),(3,1,NULL,1,1,1),
(4,2,3,NULL,2,2),(5,2,NULL,2,2,1),(6,3,1,NULL,NULL,NULL);
INSERT INTO `notification` VALUES
(1,1,'Замовлення виконано'),(2,2,'Замовлення готується'),(3,3,'Замовлення прийнято');
INSERT INTO `transaction` VALUES
(1,1,210.00,'2026-10-10'),(2,2,155.00,'2026-10-10');
COMMIT;

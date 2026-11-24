-- ЛР2. Інформаційна система ресторану. MySQL 8.4
-- Мазеїна М. О. та Опімах А. В., КІ-251
-- Виконувати у новій порожній базі; скрипт не видаляє наявні таблиці.
CREATE DATABASE IF NOT EXISTS `restaurant_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `restaurant_db`;

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


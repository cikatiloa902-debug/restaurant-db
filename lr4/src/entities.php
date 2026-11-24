<?php
declare(strict_types=1);

$clients = 'SELECT user_id AS id, CONCAT(first_name, " ", last_name, " · ", email) AS label FROM `user` ORDER BY label';
$foods = 'SELECT food_id AS id, name AS label FROM food ORDER BY name, food_id';
$drinks = 'SELECT drink_id AS id, name AS label FROM drink ORDER BY name, drink_id';
$chefs = 'SELECT chef_id AS id, name AS label FROM chef ORDER BY name, chef_id';
$orders = 'SELECT o.order_id AS id, CONCAT("#", o.order_id, " · ", u.first_name, " ", u.last_name) AS label
           FROM `order` o JOIN `user` u ON u.user_id = o.user_id ORDER BY o.order_id DESC';
$reservations = 'SELECT r.reservation_id AS id, CONCAT(r.reserved_date, " · стіл ", r.table_number, " · ", u.last_name) AS label
                 FROM reservation r JOIN `user` u ON u.user_id = r.user_id ORDER BY r.reserved_date DESC, r.reservation_id DESC';

return [
    'orders' => [
        'title' => 'Замовлення',
        'description' => 'Замовлення клієнтів та їхні статуси.',
        'pk' => 'order_id',
        'fields' => [
            'user_id' => ['Клієнт', 'select', true, $clients],
            'order_status' => ['Статус', 'text', true, 20],
        ],
        'columns' => ['client' => 'Клієнт', 'order_status' => 'Статус'],
        'list' => 'SELECT o.order_id, CONCAT(u.first_name, " ", u.last_name) AS client, o.order_status
                   FROM `order` o JOIN `user` u ON u.user_id = o.user_id
                   WHERE CAST(o.order_id AS CHAR) LIKE :number ESCAPE "=" OR CONCAT(u.first_name, " ", u.last_name) LIKE :client ESCAPE "=" OR o.order_status LIKE :status ESCAPE "="
                   ORDER BY o.order_id DESC LIMIT :limit OFFSET :offset',
        'count' => 'SELECT COUNT(*) FROM `order` o JOIN `user` u ON u.user_id = o.user_id
                    WHERE CAST(o.order_id AS CHAR) LIKE :number ESCAPE "=" OR CONCAT(u.first_name, " ", u.last_name) LIKE :client ESCAPE "=" OR o.order_status LIKE :status ESCAPE "="',
        'get' => 'SELECT user_id, order_status FROM `order` WHERE order_id = :id',
        'insert' => 'INSERT INTO `order` (user_id, order_status) VALUES (:user_id, :order_status)',
        'update' => 'UPDATE `order` SET user_id = :user_id, order_status = :order_status WHERE order_id = :id',
        'delete' => 'DELETE FROM `order` WHERE order_id = :id',
    ],
    'order-items' => [
        'title' => 'Позиції замовлень',
        'description' => 'Страви й напої у замовленнях.',
        'pk' => 'order_item_id',
        'fields' => [
            'order_id' => ['Замовлення', 'select', true, $orders],
            'food_id' => ['Страва', 'select', false, $foods],
            'drink_id' => ['Напій', 'select', false, $drinks],
            'reservation_id' => ['Бронювання', 'select', false, $reservations],
            'chef_id' => ['Кухар', 'select', false, $chefs],
        ],
        'product' => true,
        'columns' => ['order_label' => 'Замовлення', 'product' => 'Страва або напій', 'reservation' => 'Бронювання', 'chef' => 'Кухар'],
        'list' => 'SELECT i.order_item_id, CONCAT("#", o.order_id, " · ", u.last_name) AS order_label,
                          COALESCE(f.name, d.name) AS product, CONCAT(r.reserved_date, " · стіл ", r.table_number) AS reservation, c.name AS chef
                   FROM order_item i JOIN `order` o ON o.order_id = i.order_id JOIN `user` u ON u.user_id = o.user_id
                   LEFT JOIN food f ON f.food_id = i.food_id LEFT JOIN drink d ON d.drink_id = i.drink_id
                   LEFT JOIN reservation r ON r.reservation_id = i.reservation_id LEFT JOIN chef c ON c.chef_id = i.chef_id
                   ORDER BY i.order_item_id DESC',
        'get' => 'SELECT order_id, food_id, drink_id, reservation_id, chef_id FROM order_item WHERE order_item_id = :id',
        'insert' => 'INSERT INTO order_item (order_id, food_id, drink_id, reservation_id, chef_id)
                     VALUES (:order_id, :food_id, :drink_id, :reservation_id, :chef_id)',
        'update' => 'UPDATE order_item SET order_id = :order_id, food_id = :food_id, drink_id = :drink_id,
                                          reservation_id = :reservation_id, chef_id = :chef_id WHERE order_item_id = :id',
        'delete' => 'DELETE FROM order_item WHERE order_item_id = :id',
    ],
    'reservations' => [
        'title' => 'Бронювання',
        'description' => 'Заявки клієнтів на бронювання столиків.',
        'pk' => 'reservation_id',
        'fields' => [
            'user_id' => ['Клієнт', 'select', true, $clients],
            'reserved_date' => ['Дата бронювання', 'date', true],
            'table_number' => ['Номер столика', 'integer', true],
        ],
        'columns' => ['client' => 'Клієнт', 'reserved_date' => 'Дата бронювання', 'table_number' => 'Столик'],
        'list' => 'SELECT r.reservation_id, CONCAT(u.first_name, " ", u.last_name) AS client, r.reserved_date, r.table_number
                   FROM reservation r JOIN `user` u ON u.user_id = r.user_id ORDER BY r.reservation_id DESC',
        'get' => 'SELECT user_id, reserved_date, table_number FROM reservation WHERE reservation_id = :id',
        'insert' => 'INSERT INTO reservation (user_id, reserved_date, table_number) VALUES (:user_id, :reserved_date, :table_number)',
        'update' => 'UPDATE reservation SET user_id = :user_id, reserved_date = :reserved_date, table_number = :table_number WHERE reservation_id = :id',
        'delete' => 'DELETE FROM reservation WHERE reservation_id = :id',
    ],
    'food' => [
        'title' => 'Страви',
        'description' => 'Назви, описи та ціни страв у меню.',
        'pk' => 'food_id',
        'fields' => [
            'name' => ['Назва', 'text', true, 100],
            'description' => ['Опис', 'text', false, 150],
            'price' => ['Ціна, грн', 'money', true],
        ],
        'columns' => ['name' => 'Назва', 'description' => 'Опис', 'price' => 'Ціна, грн'],
        'list' => 'SELECT food_id, name, description, price FROM food ORDER BY food_id DESC',
        'get' => 'SELECT name, description, price FROM food WHERE food_id = :id',
        'insert' => 'INSERT INTO food (name, description, price) VALUES (:name, :description, :price)',
        'update' => 'UPDATE food SET name = :name, description = :description, price = :price WHERE food_id = :id',
        'delete' => 'DELETE FROM food WHERE food_id = :id',
    ],
    'drinks' => [
        'title' => 'Напої',
        'description' => 'Назви, описи та ціни напоїв у меню.',
        'pk' => 'drink_id',
        'fields' => [
            'name' => ['Назва', 'text', true, 100],
            'description' => ['Опис', 'text', false, 150],
            'price' => ['Ціна, грн', 'money', true],
        ],
        'columns' => ['name' => 'Назва', 'description' => 'Опис', 'price' => 'Ціна, грн'],
        'list' => 'SELECT drink_id, name, description, price FROM drink ORDER BY drink_id DESC',
        'get' => 'SELECT name, description, price FROM drink WHERE drink_id = :id',
        'insert' => 'INSERT INTO drink (name, description, price) VALUES (:name, :description, :price)',
        'update' => 'UPDATE drink SET name = :name, description = :description, price = :price WHERE drink_id = :id',
        'delete' => 'DELETE FROM drink WHERE drink_id = :id',
    ],
    'clients' => [
        'title' => 'Користувачі',
        'description' => 'Контактні записи клієнтів ресторану.',
        'pk' => 'user_id',
        'fields' => [
            'first_name' => ['Ім’я', 'text', true, 50],
            'last_name' => ['Прізвище', 'text', true, 50],
            'email' => ['Електронна пошта', 'email', true, 100],
            'password' => ['Пароль', 'password', true],
        ],
        'columns' => ['first_name' => 'Ім’я', 'last_name' => 'Прізвище', 'email' => 'Електронна пошта'],
        'list' => 'SELECT user_id, first_name, last_name, email FROM `user` ORDER BY user_id DESC',
        'get' => 'SELECT first_name, last_name, email FROM `user` WHERE user_id = :id',
        'insert' => 'INSERT INTO `user` (first_name, last_name, email, password) VALUES (:first_name, :last_name, :email, :password)',
        'update' => 'UPDATE `user` SET first_name = :first_name, last_name = :last_name, email = :email,
                                      password = COALESCE(:password, password) WHERE user_id = :id',
        'delete' => 'DELETE FROM `user` WHERE user_id = :id',
        'unique' => ['email', 'Користувач із такою електронною поштою вже є.'],
    ],
    'chefs' => [
        'title' => 'Кухарі',
        'description' => 'Імена кухарів та напрями їхньої роботи.',
        'pk' => 'chef_id',
        'fields' => [
            'name' => ['Ім’я', 'text', true, 50],
            'specialization' => ['Напрям роботи', 'text', false, 50],
        ],
        'columns' => ['name' => 'Ім’я', 'specialization' => 'Напрям роботи'],
        'list' => 'SELECT chef_id, name, specialization FROM chef ORDER BY chef_id DESC',
        'get' => 'SELECT name, specialization FROM chef WHERE chef_id = :id',
        'insert' => 'INSERT INTO chef (name, specialization) VALUES (:name, :specialization)',
        'update' => 'UPDATE chef SET name = :name, specialization = :specialization WHERE chef_id = :id',
        'delete' => 'DELETE FROM chef WHERE chef_id = :id',
    ],
    'specialties' => [
        'title' => 'Спеціалізації',
        'description' => 'Страви й напої, які може готувати кожен кухар.',
        'pk' => 'chef_specialty_id',
        'fields' => [
            'chef_id' => ['Кухар', 'select', true, $chefs],
            'food_id' => ['Страва', 'select', false, $foods],
            'drink_id' => ['Напій', 'select', false, $drinks],
        ],
        'product' => true,
        'columns' => ['chef' => 'Кухар', 'kind' => 'Вид', 'product' => 'Страва або напій'],
        'list' => 'SELECT s.chef_specialty_id, c.name AS chef, IF(s.food_id IS NULL, "Напій", "Страва") AS kind,
                          COALESCE(f.name, d.name) AS product
                   FROM chef_specialty s JOIN chef c ON c.chef_id = s.chef_id
                   LEFT JOIN food f ON f.food_id = s.food_id LEFT JOIN drink d ON d.drink_id = s.drink_id
                   ORDER BY s.chef_specialty_id DESC',
        'get' => 'SELECT chef_id, food_id, drink_id FROM chef_specialty WHERE chef_specialty_id = :id',
        'insert' => 'INSERT INTO chef_specialty (chef_id, food_id, drink_id) VALUES (:chef_id, :food_id, :drink_id)',
        'update' => 'UPDATE chef_specialty SET chef_id = :chef_id, food_id = :food_id, drink_id = :drink_id WHERE chef_specialty_id = :id',
        'delete' => 'DELETE FROM chef_specialty WHERE chef_specialty_id = :id',
        'unique' => ['chef_id', 'Цю страву або напій уже додано до спеціалізацій кухаря.'],
    ],
    'notifications' => [
        'title' => 'Сповіщення',
        'description' => 'Повідомлення про замовлення.',
        'pk' => 'notification_id',
        'fields' => [
            'order_id' => ['Замовлення', 'select', true, $orders],
            'message' => ['Повідомлення', 'text', true, 255],
        ],
        'columns' => ['order_label' => 'Замовлення', 'message' => 'Повідомлення'],
        'list' => 'SELECT n.notification_id, CONCAT("#", o.order_id, " · ", u.last_name) AS order_label, n.message
                   FROM notification n JOIN `order` o ON o.order_id = n.order_id JOIN `user` u ON u.user_id = o.user_id
                   ORDER BY n.notification_id DESC',
        'get' => 'SELECT order_id, message FROM notification WHERE notification_id = :id',
        'insert' => 'INSERT INTO notification (order_id, message) VALUES (:order_id, :message)',
        'update' => 'UPDATE notification SET order_id = :order_id, message = :message WHERE notification_id = :id',
        'delete' => 'DELETE FROM notification WHERE notification_id = :id',
        'unique' => ['order_id', 'Для цього замовлення вже є сповіщення.'],
    ],
    'payments' => [
        'title' => 'Оплати',
        'description' => 'Суми та дати оплат замовлень.',
        'pk' => 'transaction_id',
        'fields' => [
            'order_id' => ['Замовлення', 'select', true, $orders],
            'amount' => ['Сума, грн', 'money', true],
            'transaction_date' => ['Дата оплати', 'date', true],
        ],
        'columns' => ['order_label' => 'Замовлення', 'amount' => 'Сума, грн', 'transaction_date' => 'Дата оплати'],
        'list' => 'SELECT t.transaction_id, CONCAT("#", o.order_id, " · ", u.last_name) AS order_label, t.amount, t.transaction_date
                   FROM `transaction` t JOIN `order` o ON o.order_id = t.order_id JOIN `user` u ON u.user_id = o.user_id
                   ORDER BY t.transaction_id DESC',
        'get' => 'SELECT order_id, amount, transaction_date FROM `transaction` WHERE transaction_id = :id',
        'insert' => 'INSERT INTO `transaction` (order_id, amount, transaction_date) VALUES (:order_id, :amount, :transaction_date)',
        'update' => 'UPDATE `transaction` SET order_id = :order_id, amount = :amount, transaction_date = :transaction_date WHERE transaction_id = :id',
        'delete' => 'DELETE FROM `transaction` WHERE transaction_id = :id',
        'unique' => ['order_id', 'Для цього замовлення вже є оплата.'],
    ],
];

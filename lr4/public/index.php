<?php
declare(strict_types=1);

require __DIR__ . '/../src/db.php';
require __DIR__ . '/../src/helpers.php';
require __DIR__ . '/../src/forms.php';
require __DIR__ . '/../src/orders.php';
$entities = require __DIR__ . '/../src/entities.php';

session_start(['cookie_httponly' => true, 'cookie_samesite' => 'Lax', 'use_strict_mode' => true]);
header('Content-Type: text/html; charset=UTF-8');
http_response_code(200);

$section = input($_GET, 'section') ?: 'orders';
$action = input($_GET, 'action') ?: 'list';
$method = $_SERVER['REQUEST_METHOD'];
$entity = $entities[$section] ?? null;
$mode = 'error';
$title = 'Помилка';
$notice = $_SESSION['flash'] ?? null;
unset($_SESSION['flash']);

try {
    if (!$entity || !in_array($action, ['list', 'create', 'edit', 'confirm', 'delete'], true)) {
        http_response_code(404);
        $message = 'Цієї сторінки немає.';
    } elseif (!in_array($method, ['GET', 'HEAD', 'POST'], true)
        || ($action === 'delete' && $method !== 'POST')
        || ($method === 'POST' && !in_array($action, ['create', 'edit', 'delete'], true))) {
        header('Allow: ' . ($action === 'delete' ? 'POST' : (in_array($action, ['create', 'edit'], true) ? 'GET, HEAD, POST' : 'GET, HEAD')));
        http_response_code(405);
        $message = 'Цей метод для сторінки недоступний.';
    } elseif ($method === 'POST' && !validCsrf()) {
        header('HTTP/1.1 419 Page Expired', true, 419);
        $message = 'Форма застаріла. Відкрийте її знову та повторіть дію.';
    } elseif ($action === 'list') {
        $title = $entity['title'];
        $search = input($_GET, 'q');
        if (!preg_match('/\A.{0,100}\z/us', $search)) {
            $search = '';
        }
        if (isset($entity['count'])) {
            $term = '%' . strtr($search, ['=' => '==', '%' => '=%', '_' => '=_']) . '%';
            $bindings = ['number' => $term, 'client' => $term, 'status' => $term];
            $total = (int) query($entity['count'], $bindings)->fetchColumn();
            $pageSize = 8;
            $pages = max(1, (int) ceil($total / $pageSize));
            $page = min($pages, positiveInt(input($_GET, 'page')) ?? 1);
            $rows = query($entity['list'], $bindings + ['limit' => $pageSize, 'offset' => ($page - 1) * $pageSize])->fetchAll();
        } else {
            $rows = query($entity['list'])->fetchAll();
            $total = count($rows);
        }
        $mode = 'list';
    } else {
        $id = positiveInt(input($_GET, 'id'));
        $record = $action === 'create' ? [] : ($id === null ? false : query($entity['get'], ['id' => $id])->fetch());

        if ($record === false) {
            http_response_code(404);
            $message = 'Запис не знайдено.';
        } elseif ($action === 'confirm') {
            $title = 'Видалення запису';
            $mode = 'confirm';
        } elseif ($action === 'delete') {
            try {
                if (query($entity['delete'], ['id' => $id])->rowCount() === 0) {
                    http_response_code(404);
                    $message = 'Запис не знайдено.';
                } else {
                    redirect(url($section), 'Запис видалено.');
                }
            } catch (PDOException $exception) {
                if ((int) ($exception->errorInfo[1] ?? 0) !== 1451) {
                    throw $exception;
                }
                redirect(url($section), 'Видалення неможливе, бо цей запис використовується в інших розділах.', 'error');
            }
        } else {
            $creating = $action === 'create';
            $title = $creating ? 'Додавання запису' : 'Редагування запису';
            $fields = $entity['fields'];
            $compound = $section === 'orders' && $creating;
            if ($compound) {
                $choicesForItem = $entities['order-items']['fields'];
                $fields['food_id'] = $choicesForItem['food_id'];
                $fields['drink_id'] = $choicesForItem['drink_id'];
                $record['order_status'] = 'new';
            }
            if (!$creating && isset($fields['password'])) {
                $fields['password'][2] = false;
            }
            $choices = fieldChoices($fields);
            $values = $record;
            $errors = [];
            if ($method === 'POST') {
                foreach ($fields as $name => $field) {
                    $values[$name] = input($_POST, $name, $field[1] !== 'password');
                }
                [$data, $errors] = validateForm($fields, $choices, $values, $entity['product'] ?? false);
                if (!$errors) {
                    try {
                        if ($compound) {
                            $id = createOrder(['user_id' => $data['user_id'], 'order_status' => $data['order_status']], $data['food_id'], $data['drink_id'], $entities);
                            $positions = (int) ($data['food_id'] !== null) + (int) ($data['drink_id'] !== null);
                            redirect(url($section), "Замовлення №$id створено. Додано позицій: $positions.");
                        }
                        if ($creating) {
                            query($entity['insert'], $data);
                        } else {
                            $updated = query($entity['update'], $data + ['id' => $id])->rowCount();
                            if ($updated === 0 && !query($entity['get'], ['id' => $id])->fetch()) {
                                http_response_code(404);
                                throw new RuntimeException('Запис не знайдено.');
                            }
                        }
                        redirect(url($section), $creating ? 'Запис додано.' : 'Зміни збережено.');
                    } catch (PDOException $exception) {
                        $errorNumber = (int) ($exception->errorInfo[1] ?? 0);
                        if ($compound) {
                            error_log($exception->getMessage());
                            $errors['_form'] = 'Замовлення не збережено. Зміни відкотилися. Перевірте вибрані дані та повторіть спробу.';
                            http_response_code(409);
                        } elseif ($errorNumber === 1062 && isset($entity['unique'])) {
                            [$errorField, $errorText] = $entity['unique'];
                            $errors[$errorField] = $errorText;
                        } elseif ($errorNumber === 1452) {
                            $errors['_form'] = 'Пов’язаний запис уже недоступний. Оновіть форму й виберіть інший запис.';
                        } else {
                            throw $exception;
                        }
                    }
                }
                if (http_response_code() < 400) {
                    http_response_code(422);
                }
            }
            $mode = 'form';
        }
    }
} catch (PDOException $exception) {
    error_log($exception->getMessage());
    http_response_code(500);
    $message = 'Не вдалося виконати операцію з базою даних. Спробуйте пізніше.';
} catch (RuntimeException $exception) {
    $message = $exception->getMessage();
}

require __DIR__ . '/../src/view.php';

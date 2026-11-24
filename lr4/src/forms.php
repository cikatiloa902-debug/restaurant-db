<?php
declare(strict_types=1);

function fieldChoices(array $fields): array
{
    $choices = [];
    foreach ($fields as $name => $field) {
        if ($field[1] === 'select') {
            $choices[$name] = query($field[3])->fetchAll(PDO::FETCH_KEY_PAIR);
        }
    }
    return $choices;
}

function validateForm(array $fields, array $choices, array $submitted, bool $singleProduct): array
{
    $data = [];
    $errors = [];
    foreach ($fields as $name => [$label, $type, $required]) {
        $value = $submitted[$name];
        $limit = $fields[$name][3] ?? null;
        $data[$name] = $value === '' ? null : $value;
        if ($value === '') {
            if ($required) {
                $errors[$name] = 'Заповніть це поле.';
            }
            continue;
        }

        switch ($type) {
            case 'select':
                $data[$name] = positiveInt($value);
                if ($data[$name] === null || !array_key_exists($data[$name], $choices[$name])) {
                    $errors[$name] = 'Виберіть наявний запис зі списку.';
                }
                break;
            case 'integer':
                $data[$name] = positiveInt($value);
                if ($data[$name] === null) {
                    $errors[$name] = 'Вкажіть додатне ціле число до 2 147 483 647.';
                }
                break;
            case 'money':
                $data[$name] = str_replace(',', '.', $value);
                if (!preg_match('/\A\d{1,8}(?:\.\d{1,2})?\z/', $data[$name])) {
                    $errors[$name] = 'Вкажіть суму від 0 до 99 999 999,99 з точністю до двох знаків.';
                }
                break;
            case 'date':
                $date = DateTimeImmutable::createFromFormat('!Y-m-d', $value);
                if (!$date || $date->format('Y-m-d') !== $value || $value < '1000-01-01' || $value > '9999-12-31') {
                    $errors[$name] = 'Вкажіть коректну дату у форматі РРРР-ММ-ДД.';
                }
                break;
            case 'password':
                if (strlen($value) < 8 || strlen($value) > 72 || str_contains($value, "\0")) {
                    $errors[$name] = 'Введіть пароль завдовжки від 8 до 72 байтів.';
                } else {
                    $data[$name] = password_hash($value, PASSWORD_DEFAULT);
                }
                break;
            default:
                $length = preg_match_all('/./us', $value);
                if ($length === false || str_contains($value, "\0")) {
                    $errors[$name] = 'Введіть коректний текст.';
                } elseif ($length > $limit) {
                    $errors[$name] = 'Максимальна довжина — ' . $limit . ' символів.';
                } elseif ($type === 'email' && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
                    $errors[$name] = 'Вкажіть коректну електронну адресу.';
                }
        }
    }

    if ($singleProduct && !isset($errors['food_id']) && !isset($errors['drink_id'])) {
        if (($data['food_id'] === null) === ($data['drink_id'] === null)) {
            $errors['food_id'] = 'Виберіть одну страву або один напій.';
        }
    }

    return [$data, $errors];
}

<?php
declare(strict_types=1);

function h(mixed $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function input(array $source, string $key, bool $trim = true): string
{
    $value = $source[$key] ?? '';
    return is_string($value) ? ($trim ? trim($value) : $value) : '';
}

function positiveInt(string $value): ?int
{
    $number = filter_var($value, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1, 'max_range' => 2147483647]]);
    return $number === false ? null : $number;
}

function url(string $entity, array $params = []): string
{
    return '/?' . http_build_query(['section' => $entity] + $params);
}

function redirect(string $target, string $message, string $kind = 'ok'): never
{
    $_SESSION['flash'] = ['text' => $message, 'kind' => $kind];
    header('Location: ' . $target, true, 303);
    exit;
}

function csrfToken(): string
{
    return $_SESSION['csrf'] ??= bin2hex(random_bytes(32));
}

function validCsrf(): bool
{
    return isset($_SESSION['csrf']) && hash_equals($_SESSION['csrf'], input($_POST, 'csrf'));
}

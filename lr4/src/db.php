<?php
declare(strict_types=1);

function db(): PDO
{
    static $connection;
    return $connection ??= new PDO(
        'mysql:host=' . getenv('DB_HOST') . ';port=' . (getenv('DB_PORT') ?: '3306') . ';dbname=' . getenv('DB_NAME') . ';charset=utf8mb4',
        (string) getenv('DB_USER'),
        (string) getenv('DB_PASSWORD'),
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
}

function query(string $sql, array $params = []): PDOStatement
{
    $statement = db()->prepare($sql);
    foreach ($params as $name => $value) {
        $type = match (true) {
            is_int($value) => PDO::PARAM_INT,
            $value === null => PDO::PARAM_NULL,
            default => PDO::PARAM_STR,
        };
        $statement->bindValue(':' . $name, $value, $type);
    }
    $statement->execute();

    return $statement;
}

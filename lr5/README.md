# Лабораторна робота № 5 — крок 1

**Проєкт «Ресторан».** Мазеїна Марина Олегівна та Опімах Андрій Володимирович, КІ-251.

Docker Compose запускає два сервери MySQL 8.0 з окремими томами. Під час першого запуску основний сервер завантажує схему з ЛР № 2 та тестові дані з ЛР № 2–3. Підключення репліки до джерела й перенесення даних виконуються на кроці 6.

## Запуск у Windows

Запустіть Docker Desktop і відкрийте PowerShell у розпакованій папці `lr5`, де міститься `docker-compose.yml`.

```powershell
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    $env:Path += ";$env:LOCALAPPDATA\Programs\DockerDesktop\resources\bin"
}
if (!(Test-Path .env)) { Copy-Item .env.example .env }
docker compose up -d --wait
docker compose ps
```

Дочекайтеся статусу `healthy` для обох сервісів. Основний сервер слухає `127.0.0.1:3307`, репліка — `127.0.0.1:3308`. Якщо порт зайнятий іншою лабораторною, можна змінити відповідну змінну `PRIMARY_PORT` або `REPLICA_PORT` у локальному файлі `.env`.

## Перевірка обох серверів

```powershell
docker compose exec -T primary sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "SELECT VERSION(), @@server_id, @@gtid_mode;"'
docker compose exec -T replica sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "SELECT VERSION(), @@server_id, @@gtid_mode;"'
```

Очікується `server_id=1` для `primary`, `server_id=2` для `replica` і `gtid_mode=ON` на обох. Для кроку 1 зробіть скриншот `docker compose ps` і результатів двох команд. Команда `docker compose down` зупиняє стенд і зберігає обидва томи.

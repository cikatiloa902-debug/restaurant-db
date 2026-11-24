FROM php:8.3-apache
RUN docker-php-ext-install pdo_mysql \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY public/ /var/www/html/
COPY src/ /var/www/src/

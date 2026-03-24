FROM php:8.4-cli

RUN apt-get update && apt-get install -y \
        unzip \
        git \
        libzip-dev \
        zlib1g-dev \
    && docker-php-ext-install zip \
    && pecl install opentelemetry \
    && docker-php-ext-enable opentelemetry \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY composer.json ./
RUN composer install --no-interaction --no-scripts

COPY . .

CMD ["php", "index.php"]

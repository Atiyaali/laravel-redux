FROM node:14 as frontend

WORKDIR /app

COPY ./package.json ./

RUN npm install

COPY . .

RUN npm run production



FROM php:7.4-fpm as backend

RUN apt-get update && apt-get install -y \
netcat-openbsd\
    git \
    curl \
    zip \
    libzip-dev \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev 

RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip
COPY --from=composer:1.10 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction 

COPY --from=frontend /app/public /app/public


FROM php:7.4-fpm  as final

WORKDIR /app
RUN apt-get update && apt-get install -y \
netcat-openbsd\
    git \
    curl \
    zip \
    libzip-dev \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev 

RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip

COPY --from=backend /app /app



COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh
RUN sed -i 's|listen = 127.0.0.1:9000|listen = 9000|' /usr/local/etc/php-fpm.d/www.conf

# RUN mkdir -p /app/storage/logs \
#     && touch /app/storage/logs/laravel.log \
#     && chown -R www-data:www-data /app/storage /app/bootstrap/cache \
#     && chmod -R 775 /app/storage /app/bootstrap/cache
# Fix Laravel permissions
RUN mkdir -p storage bootstrap/cache \
 && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 9000

USER www-data
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]

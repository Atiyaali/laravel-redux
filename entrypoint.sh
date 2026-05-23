#!/bin/sh

echo "starting laravel application"

# chown -R www-data:www-data storage bootstrap/cache
# chmod -R 777 storage bootstrap/cache
# chown www-data:www-data /app/storage/logs/laravel.log
# chmod 666 /app/storage/logs/laravel.log
if [ ! -f .env ]; then
cp .env.example .env
fi


if ! grep -q "APP_KEY=base64" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi


php artisan config:clear || true
php artisan cache:clear || true
# Ensure storage & cache dirs exist + permissions
mkdir -p storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache || true
chmod -R 775 storage bootstrap/cache || true

DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-3306}

until nc -z "$DB_HOST" "$DB_PORT"; do
  echo "Waiting for database at $DB_HOST:$DB_PORT..."
  sleep 3
done

echo "Database is up!"

# Run migrations safely
php artisan migrate --force 

echo "Migration completed."


# php artisan package:discover

echo "Laravel setup completed."
exec php-fpm
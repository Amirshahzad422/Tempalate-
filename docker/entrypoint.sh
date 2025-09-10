#!/usr/bin/env sh
set -e

# Ensure runtime dirs
mkdir -p /run/php /run/nginx

# App bootstrap
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true
php artisan storage:link || true

# Set correct permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true

exec /usr/bin/supervisord -c /etc/supervisord.conf 
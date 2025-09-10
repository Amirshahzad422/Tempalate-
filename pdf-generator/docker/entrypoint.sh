#!/usr/bin/env sh
set -e

mkdir -p /run/php /run/nginx
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true
php artisan storage:link || true
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true
exec /usr/bin/supervisord -c /etc/supervisord.conf 
# syntax=docker/dockerfile:1
FROM php:8.2-fpm-alpine AS base

RUN apk add --no-cache nginx supervisor bash curl git libzip-dev icu-dev tzdata
RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql zip intl

COPY docker/php.ini /usr/local/etc/php/conf.d/zz-custom.ini

FROM composer:2 AS composer_stage
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-progress --prefer-dist --optimize-autoloader

FROM node:18-alpine AS node_stage
WORKDIR /app
ENV npm_config_legacy_peer_deps=true
COPY package.json package-lock.json* ./
RUN npm install --no-audit --prefer-offline --legacy-peer-deps
COPY resources ./resources
COPY vite.config.* ./
COPY postcss.config.* ./
COPY tailwind.config.* ./
RUN npm run build || true

FROM base AS app
WORKDIR /var/www/html
COPY . ./
COPY --from=composer_stage /app/vendor ./vendor
COPY --from=node_stage /app/public/build ./public/build
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p /run/nginx && chown -R www-data:www-data storage bootstrap/cache
EXPOSE 8080
ENV APP_ENV=production APP_DEBUG=false PHP_FPM_LISTEN=/run/php-fpm.sock
CMD ["/entrypoint.sh"] 
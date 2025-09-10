# syntax=docker/dockerfile:1

# -------- Base PHP image with extensions --------
FROM php:8.2-fpm-alpine AS base

RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
    curl \
    git \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libzip-dev \
    oniguruma-dev \
    freetype-dev \
    icu-dev \
    tzdata \
    nodejs \
    npm

# PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install -j$(nproc) gd pdo pdo_mysql pdo_pgsql zip intl

# Configure PHP
COPY docker/php.ini /usr/local/etc/php/conf.d/zz-custom.ini

# -------- Composer stage --------
FROM composer:2 AS composer_stage
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-progress --prefer-dist --optimize-autoloader

# -------- Node build stage (Node 18 LTS) --------
FROM node:18-alpine AS node_stage
WORKDIR /app
ENV npm_config_legacy_peer_deps=true
COPY package.json package-lock.json* ./
RUN npm install --no-audit --prefer-offline --legacy-peer-deps
COPY resources ./resources
COPY vite.config.* ./
COPY tsconfig.json* ./
COPY postcss.config.* ./
COPY tailwind.config.* ./
RUN npm run build || (echo "No front-end build needed" && true)

# -------- Final stage --------
FROM base AS app
WORKDIR /var/www/html

# Copy app source
COPY . ./

# Copy vendor from composer stage (optimize later with cache mounts)
COPY --from=composer_stage /app/vendor ./vendor

# Copy built assets if present
COPY --from=node_stage /app/public/build ./public/build

# Nginx & Supervisor configs
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /run/nginx && \
    chown -R www-data:www-data storage bootstrap/cache

# Expose web port
EXPOSE 8080

ENV APP_ENV=production \
    APP_DEBUG=false \
    PHP_FPM_LISTEN=/run/php-fpm.sock

# Default command runs nginx+php-fpm
CMD ["/entrypoint.sh"] 
# Stage 1: PHP dependencies with Composer
FROM php:8.4-fpm-bullseye AS php-build

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libpq-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql zip bcmath gd intl opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy app files
COPY . .

# Install PHP dependencies (vendor)
RUN composer install --no-dev --optimize-autoloader

# Stage 2: Node for frontend build
FROM node:20 AS node-build

WORKDIR /var/www

# Copy app files (needed for npm build)
COPY . .

# Install frontend dependencies and build assets
RUN npm install && npm run build

# Stage 3: Production image with Nginx
FROM nginx:alpine AS production

# Install PHP-FPM
RUN apk add --no-cache \
    php82 \
    php82-fpm \
    php82-pdo \
    php82-pdo_mysql \
    php82-pdo_pgsql \
    php82-zip \
    php82-bcmath \
    php82-gd \
    php82-intl \
    php82-opcache \
    php82-json \
    php82-mbstring \
    php82-xml \
    php82-curl \
    php82-tokenizer \
    php82-fileinfo \
    php82-openssl

WORKDIR /var/www

# Copy PHP application from php-build stage
COPY --from=php-build /var/www /var/www

# Copy built frontend assets from node-build stage
COPY --from=node-build /var/www/public/build /var/www/public/build

# Create nginx configuration
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /var/www/public; \
    index index.php; \
    \
    location / { \
        try_files $uri $uri/ /index.php?$query_string; \
    } \
    \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        fastcgi_index index.php; \
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name; \
        include fastcgi_params; \
    } \
    \
    location ~ /\.ht { \
        deny all; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Fix permissions for Laravel
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Ensure QR code storage folder exists
RUN mkdir -p /var/www/storage/app/public/qrcodes && \
    chown -R www-data:www-data /var/www/storage/app/public/qrcodes

# Create startup script
RUN echo '#!/bin/sh \
php-fpm82 -D \
nginx -g "daemon off;"' > /start.sh && chmod +x /start.sh

# Expose port
EXPOSE 80

# Start both PHP-FPM and Nginx
CMD ["/start.sh"]

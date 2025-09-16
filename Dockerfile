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

# Install PHP-FPM (using edge repository for PHP 8.3+)
RUN apk add --no-cache \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
    php83 \
    php83-fpm \
    php83-pdo \
    php83-pdo_mysql \
    php83-pdo_pgsql \
    php83-zip \
    php83-bcmath \
    php83-gd \
    php83-intl \
    php83-opcache \
    php83-json \
    php83-mbstring \
    php83-xml \
    php83-curl \
    php83-tokenizer \
    php83-fileinfo \
    php83-openssl

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

# Fix permissions for Laravel (using nginx user which exists in Alpine)
RUN chown -R nginx:nginx /var/www/storage /var/www/bootstrap/cache

# Ensure QR code storage folder exists
RUN mkdir -p /var/www/storage/app/public/qrcodes && \
    chown -R nginx:nginx /var/www/storage/app/public/qrcodes

# Configure PHP-FPM to listen on port 9000
RUN echo '[global]' > /etc/php83/php-fpm.d/www.conf && \
    echo 'daemonize = no' >> /etc/php83/php-fpm.d/www.conf && \
    echo '[www]' >> /etc/php83/php-fpm.d/www.conf && \
    echo 'listen = 127.0.0.1:9000' >> /etc/php83/php-fpm.d/www.conf && \
    echo 'pm = dynamic' >> /etc/php83/php-fpm.d/www.conf && \
    echo 'pm.max_children = 5' >> /etc/php83/php-fpm.d/www.conf && \
    echo 'pm.start_servers = 2' >> /etc/php83/php-fpm.d/www.conf && \
    echo 'pm.min_spare_servers = 1' >> /etc/php83/php-fpm.d/www.conf && \
    echo 'pm.max_spare_servers = 3' >> /etc/php83/php-fpm.d/www.conf

# Create startup script
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'php-fpm83 -D' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

# Expose port
EXPOSE 80

# Start both PHP-FPM and Nginx
CMD ["/start.sh"]

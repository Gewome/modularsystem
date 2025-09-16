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

# Stage 2: Production image with Nginx
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

# Create necessary directories and fix permissions
RUN mkdir -p /var/www/storage/logs && \
    mkdir -p /var/www/storage/framework/cache && \
    mkdir -p /var/www/storage/framework/sessions && \
    mkdir -p /var/www/storage/framework/views && \
    mkdir -p /var/www/storage/app/public/qrcodes && \
    mkdir -p /var/www/bootstrap/cache && \
    chown -R nginx:nginx /var/www/storage && \
    chown -R nginx:nginx /var/www/bootstrap/cache && \
    chmod -R 775 /var/www/storage && \
    chmod -R 775 /var/www/bootstrap/cache

# Configure PHP-FPM to listen on port 9000 (simplified)
RUN sed -i 's/listen = \/run\/php-fpm83.sock/listen = 127.0.0.1:9000/' /etc/php83/php-fpm.d/www.conf && \
    sed -i 's/;listen.owner = nginx/listen.owner = nginx/' /etc/php83/php-fpm.d/www.conf && \
    sed -i 's/;listen.group = nginx/listen.group = nginx/' /etc/php83/php-fpm.d/www.conf && \
    sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /etc/php83/php-fpm.d/www.conf

# Create startup script with Laravel setup
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'echo "Setting up Laravel..."' >> /start.sh && \
    echo 'cd /var/www' >> /start.sh && \
    echo 'php artisan storage:link || echo "Storage link already exists"' >> /start.sh && \
    echo 'php artisan config:cache || echo "Config cache failed"' >> /start.sh && \
    echo 'php artisan route:cache || echo "Route cache failed"' >> /start.sh && \
    echo 'echo "Starting PHP-FPM..."' >> /start.sh && \
    echo 'php-fpm83 -D' >> /start.sh && \
    echo 'echo "Starting Nginx..."' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

# Expose port
EXPOSE 80

# Start both PHP-FPM and Nginx
CMD ["/start.sh"]

# ---------------------------
# Stage 0: Base PHP
# ---------------------------
FROM php:8.4-fpm

# Set working directory
WORKDIR /var/www/html

# ---------------------------
# Install system dependencies
# ---------------------------
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    libonig-dev \
    libpng-dev \
    libicu-dev \
    curl \
    zip \
    nodejs \
    npm \
    && docker-php-ext-install \
        pdo \
        pdo_pgsql \
        pdo_mysql \
        mbstring \
        bcmath \
        zip \
        gd \
        intl \
        fileinfo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Install Composer
# ---------------------------
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ---------------------------
# Copy project files
# ---------------------------
COPY . .

# ---------------------------
# Set permissions
# ---------------------------
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# ---------------------------
# Install PHP dependencies
# ---------------------------
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# ---------------------------
# Build Node / Vite assets
# ---------------------------
RUN npm install
RUN npm run build

# ---------------------------
# Cache Laravel config & routes
# ---------------------------
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# ---------------------------
# Expose port & start PHP-FPM
# ---------------------------
EXPOSE 9000
CMD ["php-fpm"]

# Stage 1: PHP dependencies with Composer
FROM php:8.4-fpm-bullseye AS php-build

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libpq-dev libpng-dev libonig-dev libxml2-dev \
    curl nodejs npm \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql zip bcmath gd intl opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy composer files and install dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Copy the application code
COPY . .

# Build frontend assets with Vite
RUN npm install && npm run build

# Stage 2: Production image
FROM php:8.4-fpm-bullseye

# Install PHP extensions
RUN apt-get update && apt-get install -y \
    libzip-dev libpq-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql zip bcmath gd intl opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www

# Copy built app from build stage
COPY --from=php-build /var/www /var/www

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expose port
EXPOSE 8000

# Start Laravel with PHP built-in server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]

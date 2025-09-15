# Use official PHP 8.2 with Apache
FROM php:8.2-apache

# Install system dependencies and required libraries
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    libonig-dev \
    zip \
    curl \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql mbstring bcmath zip

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . .

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Generate Laravel key
RUN php artisan key:generate --force

# Set permissions for storage & bootstrap/cache
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Expose port
EXPOSE 10000

# Start Apache
CMD ["apache2-foreground"]

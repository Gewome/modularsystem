# Use PHP 8.2 with Apache
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    libonig-dev \
    zip \
    curl \
    nodejs \
    npm \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql mbstring bcmath zip gd

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . .

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Install Node dependencies and build Vite assets
RUN npm install && npm run build

# Generate Laravel key
RUN php artisan key:generate --force

# Set permissions for storage & bootstrap/cache
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Expose Apache port
EXPOSE 10000

# Start Apache
CMD ["apache2-foreground"]

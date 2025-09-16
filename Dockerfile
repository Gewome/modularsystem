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

# Stage 3: Production image
FROM php:8.4-fpm-bullseye

# Install PHP extensions needed in production
RUN apt-get update && apt-get install -y \
    libzip-dev libpq-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql zip bcmath gd intl opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www

# Copy PHP application (including vendor) from php-build stage
COPY --from=php-build /var/www /var/www

# Copy built frontend assets from node-build stage
COPY --from=node-build /var/www/public/build /var/www/public/build

# Fix permissions for Laravel
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Ensure QR code storage folder exists
RUN mkdir -p /var/www/storage/app/public/qrcodes && \
    chown -R www-data:www-data /var/www/storage/app/public/qrcodes

# Run only safe Laravel setup commands
RUN php artisan storage:link

# Create .env file for production
RUN echo "APP_NAME=\"Bohol Northern Star College\"" > .env && \
    echo "APP_ENV=production" >> .env && \
    echo "APP_KEY=base64:RDsPbXY4+PvCLLPTd5Ri4yGTLtGTMhggGczx+iofA4Y=" >> .env && \
    echo "APP_DEBUG=false" >> .env && \
    echo "APP_URL=\${RENDER_EXTERNAL_URL:-http://localhost:8000}" >> .env && \
    echo "" >> .env && \
    echo "DB_CONNECTION=pgsql" >> .env && \
    echo "DB_HOST=\${DATABASE_HOST:-localhost}" >> .env && \
    echo "DB_PORT=\${DATABASE_PORT:-5432}" >> .env && \
    echo "DB_DATABASE=\${DATABASE_NAME:-modular_system}" >> .env && \
    echo "DB_USERNAME=\${DATABASE_USER:-modular_system_user}" >> .env && \
    echo "DB_PASSWORD=\${DATABASE_PASSWORD}" >> .env && \
    echo "" >> .env && \
    echo "PAYMONGO_PUBLIC_KEY=\${PAYMONGO_PUBLIC_KEY:-pk_test_zmmTaLjgk6pfav3LVsHnxzMX}" >> .env && \
    echo "PAYMONGO_SECRET_KEY=\${PAYMONGO_SECRET_KEY:-sk_test_72uUhgeM88acLxyEsF6hNQZp}" >> .env && \
    echo "PAYMONGO_SUCCESS_URL=\${RENDER_EXTERNAL_URL:-http://localhost:8000}/payment/success" >> .env && \
    echo "PAYMONGO_CANCEL_URL=\${RENDER_EXTERNAL_URL:-http://localhost:8000}/payment/cancel" >> .env

# Expose Laravel's serve port
EXPOSE 8000

# Run Laravel
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]

# Stage 1: Build PHP dependencies
FROM php:8.2-cli AS php-build

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git unzip curl libpng-dev libjpeg-dev libfreetype6-dev libonig-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl gd \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy composer files and install dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Copy rest of app code
COPY . .

# Stage 2: Build Node/Vite assets
FROM node:18 AS node-build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .
RUN npm run build

# Stage 3: Final runtime image
FROM php:8.2-cli

# Install system dependencies again
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libonig-dev libzip-dev unzip curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl gd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy PHP vendor + built assets
COPY --from=php-build /app /app
COPY --from=node-build /app/public/build /app/public/build

# Expose Render’s port
EXPOSE 10000

# Start Laravel server on Render’s assigned port
CMD php artisan serve --host=0.0.0.0 --port=${PORT}

# ============================================================
# Dockerfile – Laravel Backend (Production)
# Teknologi: PHP 8.3-FPM + Nginx + MySQL + Redis
# ============================================================

# === STAGE 1: Composer Dependencies ===
FROM composer:2.7 AS composer_stage

WORKDIR /app

# Install GD extension & dependencies in Alpine for Composer platform-req check
RUN apk add --no-cache \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && php -r "var_dump(extension_loaded('gd'));"

# Copy dependency files only (better Docker cache)
COPY composer.json composer.lock ./

# Install production dependencies only (no dev)
# --no-scripts: skip post-autoload-dump hooks (artisan belum ada di stage ini)
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-progress \
    --optimize-autoloader \
    --prefer-dist \
    --no-scripts

# === STAGE 2: Production Image ===
FROM php:8.3-fpm

# Copy composer binary untuk dump-autoload di build stage
COPY --from=composer_stage /usr/bin/composer /usr/bin/composer

# Set environment to production
ENV APP_ENV=production
ENV APP_DEBUG=false

# Install system dependencies (Debian Bookworm)
# Hanya menyertakan library yang terbukti dibutuhkan oleh ekstensi aktif
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    nginx \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
# (pdo_pgsql dan pdo_sqlite dihapus karena project menggunakan MySQL dan tidak ada dependensi sqlite/pgsql)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        opcache \
    && php -r "var_dump(extension_loaded('gd'));"

# Install Redis extension via PECL
RUN pecl install redis \
    && docker-php-ext-enable redis

# PHP production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# PHP-FPM configuration
COPY docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-custom.ini

# Nginx configuration
COPY docker/nginx/conf.d/default.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default \
    && rm -f /etc/nginx/sites-enabled/000-default 2>/dev/null || true

# Supervisor configuration (manages nginx + php-fpm)
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY . .

# Hapus cache framework lokal yang tidak boleh masuk ke production
RUN rm -f bootstrap/cache/*.php

# Copy vendor from build stage (ensures clean Linux vendor from composer_stage)
COPY --from=composer_stage /app/vendor ./vendor

# Regenerate autoload classmap dengan full app context (artisan & semua kelas tersedia)
RUN composer dump-autoload --optimize --no-scripts --no-dev

# Copy and set permissions
RUN mkdir -p /run/php \
    && chown -R www-data:www-data /run/php /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache \
    && chmod +x /var/www/html/docker/entrypoint.sh

# Expose port 80
EXPOSE 80

# Entrypoint script
ENTRYPOINT ["/var/www/html/docker/entrypoint.sh"]
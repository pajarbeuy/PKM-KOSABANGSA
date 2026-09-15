# ============================================================
# Dockerfile – Laravel Backend (Production)
# Teknologi: PHP 8.3-FPM + Nginx + MySQL + Redis
# ============================================================

# === STAGE 1: Composer Dependencies ===
FROM composer:2.7 AS composer_stage

WORKDIR /app

# Copy dependency files only (better Docker cache)
COPY composer.json composer.lock ./

# Install production dependencies only (no dev)
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-progress \
    --optimize-autoloader \
    --prefer-dist

# === STAGE 2: Production Image ===
FROM php:8.3-fpm

# Set environment to production
ENV APP_ENV=production
ENV APP_DEBUG=false

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libgd-dev \
    libpq-dev \
    zip \
    unzip \
    nginx \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        opcache \
        redis 2>/dev/null || true

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

# Copy vendor from build stage
COPY --from=composer_stage /app/vendor ./vendor

# Copy application code
COPY . .

# Copy and set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache \
    && chmod +x /var/www/html/docker/entrypoint.sh

# Expose port 80
EXPOSE 80

# Entrypoint script
ENTRYPOINT ["/var/www/html/docker/entrypoint.sh"]
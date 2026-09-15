#!/bin/bash
# ============================================================
# docker/entrypoint.sh – Laravel Production Startup Script
# ============================================================

set -e

echo "🚀 Starting Pertanian Kentang Backend..."

# Navigate to app directory
cd /var/www/html

# === 1. Environment Check ===
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found! Copying from .env.production..."
    if [ -f ".env.production" ]; then
        cp .env.production .env
    else
        echo "❌ ERROR: No .env file found. Please provide .env.production"
        exit 1
    fi
fi

# === 2. Generate App Key (if missing) ===
if grep -q "APP_KEY=$" .env || grep -q "APP_KEY=base64:CHANGEME" .env; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force
fi

# === 3. Wait for Database ===
echo "⏳ Waiting for database to be ready..."
MAX_TRIES=30
TRIES=0
until php artisan db:monitor 2>/dev/null || php -r "new PDO('mysql:host=${DB_HOST};port=${DB_PORT};dbname=${DB_DATABASE}', '${DB_USERNAME}', '${DB_PASSWORD}');" 2>/dev/null; do
    TRIES=$((TRIES + 1))
    if [ $TRIES -ge $MAX_TRIES ]; then
        echo "❌ Database not reachable after ${MAX_TRIES} attempts. Exiting."
        exit 1
    fi
    echo "   Attempt $TRIES/$MAX_TRIES – retrying in 3s..."
    sleep 3
done
echo "✅ Database is ready!"

# === 4. Run Migrations ===
echo "📦 Running database migrations..."
php artisan migrate --force --no-interaction

# === 5. Cache Configuration (Production Optimization) ===
echo "⚡ Caching config, routes, and views..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# === 6. Storage Link ===
echo "🔗 Creating storage symlink..."
php artisan storage:link --force 2>/dev/null || true

# === 7. Set Permissions ===
echo "🔐 Setting permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "✅ All setup complete! Starting Supervisor..."
echo ""
echo "🌐 Backend running on port 80"
echo "📡 API available at: http://[SERVER_IP]/api"
echo ""

# === 8. Start Supervisor (Nginx + PHP-FPM + Queue Worker) ===
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

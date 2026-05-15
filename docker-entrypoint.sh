#!/bin/bash
echo "🚀 Docker Entrypoint script starting..."

# DO NOT use set -e — we handle errors manually to ensure Apache always starts.

# Railway injects PORT dynamically; Apache must listen on it.
APP_PORT="${PORT:-80}"
echo "🌐 Configuring Apache to listen on port ${APP_PORT}"
sed -ri "s/^Listen [0-9]+/Listen ${APP_PORT}/" /etc/apache2/ports.conf
sed -ri "s/<VirtualHost \*:[0-9]+>/<VirtualHost *:${APP_PORT}>/" /etc/apache2/sites-available/000-default.conf

# Suppress AH00558 warning
echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install composer dependencies if autoload.php doesn't exist
if [ ! -f "vendor/autoload.php" ]; then
    echo "📦 Installing composer dependencies..."
    composer install --no-interaction --optimize-autoloader --no-dev || echo "⚠️ Composer install had issues"
fi

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📄 Creating .env from .env.example..."
    cp .env.example .env
fi

# Generate key only if APP_KEY is not already set in environment
if [ -z "$APP_KEY" ]; then
    echo "🔑 Generating APP_KEY..."
    php artisan key:generate || echo "⚠️ Key generation skipped"
else
    echo "✅ APP_KEY already set in environment"
fi

# Disable Pail in config/app.php for production (it's dev-only)
if grep -q 'Laravel.*Pail.*PailServiceProvider' config/app.php 2>/dev/null; then
    echo "🔧 Removing Pail ServiceProvider (dev-only) from config/app.php..."
    sed -i "/Laravel.*Pail.*PailServiceProvider/d" config/app.php || true
fi

# Run migrations only when explicitly enabled.
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    echo "🗄️ RUN_MIGRATIONS=true → waiting for database..."
    # Wait for database to be ready (max 30 seconds)
    DB_READY=false
    for i in $(seq 1 30); do
        if php artisan migrate:status > /dev/null 2>&1; then
            DB_READY=true
            echo "✅ Database is ready!"
            break
        fi
        echo "⏳ Waiting for database... ($i/30)"
        sleep 1
    done

    if [ "$DB_READY" = "true" ]; then
        echo "🔄 Running migrations..."
        php artisan migrate --force || echo "⚠️ Migration had issues"
        echo "🌱 Seeding demo data..."
        php artisan db:seed --force || echo "⚠️ Seeding skipped (maybe already seeded)"
    else
        echo "❌ Database not ready after 30s, skipping migrations"
    fi
else
    echo "⏭️ Skipping migrations (set RUN_MIGRATIONS=true to enable)"
fi

# Ensure locale directory exists
mkdir -p resources/lang/en

# Create storage link
php artisan storage:link --force 2>/dev/null || true

# Clear any cached config to ensure Railway env vars take effect
php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# mod_php requires mpm_prefork. Ensure only one MPM is active.
for _mpm in mpm_event mpm_worker; do
    a2dismod "$_mpm" 2>/dev/null || true
done
a2enmod mpm_prefork 2>/dev/null || true

echo "🔍 Testing Apache config..."
apache2ctl -t 2>/dev/null || true

echo "✅ Entrypoint complete! Starting Apache on port ${APP_PORT}..."
exec "$@"

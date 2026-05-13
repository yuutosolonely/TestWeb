#!/bin/bash
echo "🚀 Docker Entrypoint script starting..."
set -e

# Railway injects PORT dynamically; Apache must listen on it.
APP_PORT="${PORT:-80}"
echo "🌐 Configuring Apache to listen on port ${APP_PORT}"
sed -ri "s/^Listen [0-9]+/Listen ${APP_PORT}/" /etc/apache2/ports.conf
sed -ri "s/<VirtualHost \*:[0-9]+>/<VirtualHost *:${APP_PORT}>/" /etc/apache2/sites-available/000-default.conf

# Install composer dependencies if autoload.php doesn't exist
if [ ! -f "vendor/autoload.php" ]; then
    echo "📦 Installing composer dependencies..."
    composer install --no-interaction --optimize-autoloader
fi

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    php artisan key:generate
fi

# Run migrations only when explicitly enabled.
# This prevents container boot failure (and Railway 502) when DB is temporarily unavailable.
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    echo "🗄️ RUN_MIGRATIONS=true, running database migrations..."
    php artisan migrate --force
else
    echo "⏭️ Skipping migrations (set RUN_MIGRATIONS=true to enable)."
fi

# Seed data if needed (optional, uncomment if you want to seed on every start if tables are empty)
# php artisan db:seed --force

# Create storage link; do not fail startup if it already exists or filesystem is read-only.
php artisan storage:link --force || true

# mod_php (php:apache) requires mpm_prefork. apt/docker-php layers can leave mpm_event
# enabled as well, which causes AH00534 and a brief failed start on deploy/restart.
# Re-assert a single MPM on every container start before Apache binds the port.
for _mpm in mpm_event mpm_worker; do
    a2dismod "$_mpm" 2>/dev/null || true
done
a2enmod mpm_prefork 2>/dev/null || true
apache2ctl -t

exec "$@"

#!/bin/bash
echo "🚀 Docker Entrypoint script starting..."
set -e

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

# Run migrations
php artisan migrate --force

# Seed data if needed (optional, uncomment if you want to seed on every start if tables are empty)
# php artisan db:seed --force

# Create storage link
php artisan storage:link --force

# mod_php (php:apache) requires mpm_prefork. apt/docker-php layers can leave mpm_event
# enabled as well, which causes AH00534 and a brief failed start on deploy/restart.
# Re-assert a single MPM on every container start before Apache binds the port.
for _mpm in mpm_event mpm_worker; do
    a2dismod "$_mpm" 2>/dev/null || true
done
a2enmod mpm_prefork 2>/dev/null || true
apache2ctl -t

exec "$@"

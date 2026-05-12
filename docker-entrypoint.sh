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

exec "$@"

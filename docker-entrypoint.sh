#!/bin/bash
echo "🚀 Docker Entrypoint script starting..."

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

# Ensure locale directory exists
mkdir -p resources/lang/en

# Create storage link
php artisan storage:link --force 2>/dev/null || true

# Clear caches
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

# Start Apache in foreground
exec apache2-foreground

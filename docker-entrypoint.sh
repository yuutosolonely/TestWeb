#!/bin/bash
echo "🚀 Docker Entrypoint script starting..."

# DO NOT use set -e — we handle errors manually to ensure Apache always starts.

# Railway injects PORT dynamically; Apache must listen on it.
APP_PORT="${PORT:-80}"
echo "🌐 Configuring Apache to listen on port ${APP_PORT}"
echo "Listen ${APP_PORT}" > /etc/apache2/ports.conf
cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:${APP_PORT}>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/public
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Suppress AH00558 warning
echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install composer dependencies if autoload.php doesn't exist
if [ ! -f "vendor/autoload.php" ]; then
    echo "📦 Installing composer dependencies..."
    composer install --no-interaction --optimize-autoloader || echo "⚠️ Composer install had issues"
fi

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📄 Creating .env from .env.example..."
    cp .env.example .env
    php artisan key:generate || echo "⚠️ Key generation skipped"
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

# Create storage link
php artisan storage:link --force 2>/dev/null || true

# Clear any cached config to ensure Railway env vars take effect
php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true

# mod_php requires mpm_prefork. Ensure only one MPM is active.
for _mpm in mpm_event mpm_worker; do
    a2dismod "$_mpm" 2>/dev/null || true
done
a2enmod mpm_prefork 2>/dev/null || true

echo "🔍 Testing Apache config..."
apache2ctl -t 2>/dev/null || true

# Fix permissions again after running artisan commands as root
echo "🔒 Fixing permissions for www-data..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

echo "✅ Entrypoint complete! Starting Apache on port ${APP_PORT}..."
exec "$@"

FROM php:8.2-apache

# 1. CÀI ĐẶT THƯ VIỆN HỆ THỐNG VÀ PHP EXTENSIONS
# MPM fix MUST run after apt-get / docker-php-ext-install: those steps can re-enable
# mpm_event (AH00534: More than one MPM loaded on Railway).
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-install pdo_pgsql pgsql gd zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && (a2dismod mpm_event 2>/dev/null || true) \
    && (a2dismod mpm_worker 2>/dev/null || true) \
    && a2enmod mpm_prefork \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# 2. CÀI ĐẶT COMPOSER
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 3. THIẾT LẬP THƯ MỤC LÀM VIỆC & COPY CODE
WORKDIR /var/www/html
COPY . .
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# 4. PHÂN QUYỀN CHO THƯ MỤC STORAGE VÀ CACHE
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 5. TRỎ APACHE DOCUMENT_ROOT VÀO THƯ MỤC PUBLIC CỦA LARAVEL
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# 6. MỞ PORT 80
EXPOSE 80

# 7. COPY VÀ PHÂN QUYỀN CHẠY ENTRYPOINT SCRIPT
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
# Fix lỗi ký tự xuống dòng (CRLF) nếu code được viết trên Windows
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh

# Final MPM assert after all COPYs (image is immutable at runtime; entrypoint also re-asserts).
RUN (a2dismod mpm_event 2>/dev/null || true) \
    && (a2dismod mpm_worker 2>/dev/null || true) \
    && a2enmod mpm_prefork \
    && apache2ctl -t

# 8. KHỞI ĐỘNG
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]

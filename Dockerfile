FROM php:8.2-apache

# 1. SỬA LỖI CRASH APACHE (AH00534) TRÊN RAILWAY
# Chỉ cho phép chạy mpm_prefork, tắt các module xung đột
RUN a2dismod mpm_event mpm_worker && a2enmod mpm_prefork

# 2. CÀI ĐẶT THƯ VIỆN HỆ THỐNG VÀ PHP EXTENSIONS
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
    && docker-php-ext-enable redis

# 3. BẬT MOD_REWRITE CHO LARAVEL ROUTING
RUN a2enmod rewrite

# 4. CÀI ĐẶT COMPOSER
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. THIẾT LẬP THƯ MỤC LÀM VIỆC & COPY CODE
WORKDIR /var/www/html
COPY . .

# 6. PHÂN QUYỀN CHO THƯ MỤC STORAGE VÀ CACHE
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 7. TRỎ APACHE DOCUMENT_ROOT VÀO THƯ MỤC PUBLIC CỦA LARAVEL
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# 8. MỞ PORT 80
EXPOSE 80

# 9. COPY VÀ PHÂN QUYỀN CHẠY ENTRYPOINT SCRIPT
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
# Fix lỗi ký tự xuống dòng (CRLF) nếu code được viết trên Windows
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh

# 10. KHỞI ĐỘNG
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
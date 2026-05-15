# ⚠️ TỔNG HỢP TOÀN BỘ LỖI VÀ GIẢI PHÁP KHẮC PHỤC
## Dự án Note Management Application (Topic 10)

> [!IMPORTANT]
> Tài liệu này tổng hợp toàn bộ các lỗi kỹ thuật, khó khăn và thách thức phát sinh trong suốt quá trình xây dựng, cấu hình và triển khai dự án (từ môi trường phát triển cục bộ XAMPP, đóng gói Docker cho đến khi đưa lên nền tảng đám mây Railway). Mỗi lỗi đều được phân tích nguyên nhân gốc rễ và kèm theo giải pháp xử lý triệt để.

---

## 📋 DANH SÁCH CÁC NHÓM LỖI CHÍNH

1. [Nhóm lỗi Cấu hình Web Server & Apache (Docker/Railway)](#1-nhóm-lỗi-cấu-hình-web-server--apache)
2. [Nhóm lỗi Cơ sở dữ liệu & Migration (PostgreSQL/MySQL)](#2-nhóm-lỗi-cơ-sở-dữ-liệu--migration)
3. [Nhóm lỗi Bộ đệm & Phiên làm việc (Redis Cache/Session)](#3-nhóm-lỗi-bộ-đệm--phiên-làm-việc-redis)
4. [Nhóm lỗi Hệ thống File & Quyền truy cập (Storage/Linux)](#4-nhóm-lỗi-hệ-thống-file--quyền-truy-cập)
5. [Nhóm lỗi Tích hợp & Dịch vụ bên ngoài (SMTP Email/WebSocket)](#5-nhóm-lỗi-tích-hợp--dịch-vụ-bên-ngoài)
6. [Nhóm lỗi Giao diện & Trải nghiệm người dùng (UI/UX & Mobile)](#6-nhóm-lỗi-giao-diện--trải-nghiệm-người-dùng)

---

## 1. NHÓM LỖI CẤU HÌNH WEB SERVER & APACHE

### 1.1. Lỗi xung đột Multi-Processing Module (MPM) trên Apache
- **Triệu chứng / Báo lỗi**: Khi deploy lên Railway hoặc chạy Docker, container bị crash ngay lập tức với log:
  ```text
  AH00534: apache2: Configuration error: More than one MPM loaded.
  ```
- **Nguyên nhân**: Base image `php:8.2-apache` sử dụng module `mod_php` để chạy PHP. Module này đòi hỏi Apache phải chạy ở mô hình quy trình đơn (prefork MPM). Tuy nhiên, trong quá trình cập nhật các gói hệ thống (`apt-get update`) hoặc cài đặt một số thư viện, Apache tự động kích hoạt thêm các module MPM khác như `mpm_event` hoặc `mpm_worker`, dẫn đến xung đột khi có quá 1 MPM cùng được nạp.
- **Giải pháp khắc phục**: Đưa các lệnh vô hiệu hóa tường minh các module không tương thích vào `Dockerfile` và đảm bảo tái kiểm tra trong `docker-entrypoint.sh`:
  ```bash
  # Trong Dockerfile và Entrypoint:
  a2dismod mpm_event 2>/dev/null || true
  a2dismod mpm_worker 2>/dev/null || true
  a2enmod mpm_prefork 2>/dev/null || true
  ```

### 1.2. Lỗi 502 Bad Gateway / 500 Internal Server Error trên Cloud (Railway)
- **Triệu chứng / Báo lỗi**: Truy cập ứng dụng trên Railway nhận được trang thông báo lỗi `502 Bad Gateway` hoặc kết nối bị từ chối (Connection Refused).
- **Nguyên nhân**: Mặc định Apache lắng nghe trên cổng 80 (`Listen 80`). Tuy nhiên, nền tảng đám mây Railway cấp phát động một biến môi trường `$PORT` (ví dụ: 6412, 8080) và yêu cầu ứng dụng phải lắng nghe chính xác trên cổng đó để bộ cân bằng tải (Load Balancer) trỏ tới.
- **Giải pháp khắc phục**: Cấu hình thay đổi cổng lắng nghe của Apache một cách linh hoạt thông qua biến môi trường trong file `docker-entrypoint.sh`:
  ```bash
  APP_PORT="${PORT:-80}"
  sed -ri "s/^Listen [0-9]+/Listen ${APP_PORT}/" /etc/apache2/ports.conf
  sed -ri "s/<VirtualHost \*:[0-9]+>/<VirtualHost *:${APP_PORT}>/" /etc/apache2/sites-available/000-default.conf
  ```

### 1.3. Lỗi 419 Page Expired & Redirect HTTP/HTTPS sai (TrustProxies)
- **Triệu chứng / Báo lỗi**: Khi người dùng gửi form đăng nhập hoặc đăng ký trên môi trường Railway, trang báo lỗi `419 Page Expired` (CSRF token mismatch) hoặc bị chuyển hướng sai từ `https://` sang `http://`.
- **Nguyên nhân**: Ứng dụng chạy phía sau hệ thống Reverse Proxy / Load Balancer của Railway. Giao tiếp giữa trình duyệt và Railway là `HTTPS`, nhưng giao tiếp nội bộ giữa Railway và Docker container là `HTTP`. Do đó, Laravel hiểu nhầm rằng request đang không an toàn và tạo các đường dẫn redirect hoặc kiểm tra cookie CSRF ở dạng HTTP.
- **Giải pháp khắc phục**: 
  - Đảm bảo biến `APP_URL` trong `.env` sử dụng đúng tiền tố `https://`.
  - Trong `app/Providers/AppServiceProvider.php`, ép buộc sử dụng HTTPS nếu môi trường là production:
    ```php
    use Illuminate\Support\Facades\URL;
    if (config('app.env') === 'production') {
        URL::forceScheme('https');
    }
    ```

---

## 2. NHÓM LỖI CƠ SỞ DỮ LIỆU & MIGRATION

### 2.1. Lỗi Connection Refused khi chạy `docker-compose up`
- **Triệu chứng / Báo lỗi**:
  ```text
  SQLSTATE[HY000] [2002] Connection refused
  ```
- **Nguyên nhân**: Trong môi trường Docker Compose, các container được khởi động gần như đồng thời. Container ứng dụng web (`app`) khởi động rất nhanh và chạy script `docker-entrypoint.sh` thực thi câu lệnh `php artisan migrate`. Tại thời điểm này, container PostgreSQL (`db`) đang trong quá trình khởi tạo dữ liệu ban đầu, chưa sẵn sàng chấp nhận các kết nối TCP.
- **Giải pháp khắc phục**:
  - Trong `docker-compose.yml`, thiết lập cơ chế kiểm tra sức khỏe `healthcheck` cho service `db` và ràng buộc `depends_on: condition: service_healthy` ở service `app`.
  - Trong `docker-entrypoint.sh`, bổ sung vòng lặp kiểm tra kết nối CSDL (chờ tối đa 30 giây) trước khi thực thi migrate:
    ```bash
    DB_READY=false
    for i in $(seq 1 30); do
        if php artisan migrate:status > /dev/null 2>&1; then
            DB_READY=true
            break
        fi
        sleep 1
    done
    ```

### 2.2. Lỗi bảng CSDL không tồn tại sau khi Deploy
- **Triệu chứng / Báo lỗi**: `Relation "users" does not exist` hoặc `Table "notes" not found`.
- **Nguyên nhân**: Khi deploy tự động lên production, hệ thống bỏ qua việc chạy các file migration do mặc định Laravel yêu cầu xác nhận `yes/no` khi chạy migrate ở chế độ production.
- **Giải pháp khắc phục**: Luôn sử dụng cờ `--force` khi chạy migration và seed tự động trong script khởi động:
  ```bash
  php artisan migrate --force
  php artisan db:seed --force
  ```

---

## 3. NHÓM LỖI BỘ ĐỆM & PHIÊN LÀM VIỆC (REDIS)

### 3.1. Lỗi không tìm thấy Class Redis hoặc Extension Redis chưa được nạp
- **Triệu chứng / Báo lỗi**:
  ```text
  Class 'Redis' not found hoặc Predis\Connection\ConnectionException
  ```
- **Nguyên nhân**: Base image PHP không cài đặt sẵn extension của Redis. Nếu chỉ cấu hình trong Laravel mà không cài đặt driver ở tầng C++ (PECL), PHP không thể kết nối tới Redis server.
- **Giải pháp khắc phục**: Bổ sung cài đặt và kích hoạt extension Redis trong `Dockerfile`:
  ```bash
  RUN pecl install redis && docker-php-ext-enable redis
  ```

### 3.2. Lỗi mất kết nối Session khi dùng Redis trong Docker Network
- **Triệu chứng / Báo lỗi**: Người dùng đăng nhập thành công nhưng khi chuyển sang trang khác lại lập tức bị văng ra (log out). Lỗi kết nối tới `127.0.0.1:6379`.
- **Nguyên nhân**: Trong file cấu hình `.env` mặc định, biến `REDIS_HOST=127.0.0.1`. Khi chạy trong Docker, mỗi container là một máy chủ độc lập. Container ứng dụng web không thể tìm thấy Redis ở localhost của chính nó, mà phải kết nối qua tên service của container Redis.
- **Giải pháp khắc phục**: Cấu hình lại các tham số trong `.env` hoặc `docker-compose.yml` sử dụng tên service làm hostname:
  ```env
  REDIS_HOST=redis
  SESSION_DRIVER=redis
  CACHE_STORE=redis
  QUEUE_CONNECTION=redis
  ```

---

## 4. NHÓM LỖI HỆ THỐNG FILE & QUYỀN TRUY CẬP

### 4.1. Lỗi hiển thị ảnh tải lên (Lỗi 404 Not Found)
- **Triệu chứng / Báo lỗi**: Ảnh đại diện của người dùng hoặc các ảnh đính kèm vào ghi chú hiển thị icon lỗi (Broken image).
- **Nguyên nhân**: Khi upload, Laravel lưu file tại thư mục vật lý `storage/app/public/`. Tuy nhiên, web server (Apache) chỉ truy cập được vào thư mục `public/`.
- **Giải pháp khắc phục**: Tạo liên kết tượng trưng (symbolic link) từ `public/storage` trỏ về `storage/app/public`. Tích hợp lệnh này vào script khởi động:
  ```bash
  php artisan storage:link --force
  ```

### 4.2. Lỗi Permission Denied (500 Internal Server Error trên Linux)
- **Triệu chứng / Báo lỗi**:
  ```text
  The stream or file "/var/www/html/storage/logs/laravel.log" could not be opened in append mode: failed to open stream: Permission denied.
  ```
- **Nguyên nhân**: Khi container chạy lệnh composer hoặc khởi chạy, user thực thi có thể là `root`. Trong khi đó, tiến trình Apache phục vụ người dùng web chạy dưới quyền của user `www-data`. Khi `www-data` không có quyền ghi vào thư mục `storage` và `bootstrap/cache`, ứng dụng lập tức báo lỗi 500.
- **Giải pháp khắc phục**: Phân quyền tường minh trong `Dockerfile`:
  ```bash
  RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
  ```

### 4.3. Lỗi CRLF Line Endings khi chạy Script trên Linux
- **Triệu chứng / Báo lỗi**:
  ```text
  exec /usr/local/bin/docker-entrypoint.sh: no such file or directory hoặc /bin/bash^M: bad interpreter
  ```
- **Nguyên nhân**: File `docker-entrypoint.sh` được chỉnh sửa trên hệ điều hành Windows, nơi ký tự kết thúc dòng là `CRLF` (`\r\n`). Khi đưa vào môi trường Linux trong Docker, Linux không nhận diện được ký tự `\r` và báo lỗi không tìm thấy trình thông dịch.
- **Giải pháp khắc phục**: Chuyển đổi định dạng dòng về chuẩn Linux (`LF`) tự động trong `Dockerfile`:
  ```bash
  RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh
  ```

---

## 5. NHÓM LỖI TÍCH HỢP & DỊCH VỤ BÊN NGOÀI

### 5.1. Lỗi gửi Email / Mã OTP xác thực thất bại
- **Triệu chứng / Báo lỗi**:
  ```text
  Connection could not be established with host smtp.gmail.com:stream_socket_client(): unable to connect
  hoặc 535 5.7.8 Username and Password not accepted.
  ```
- **Nguyên nhân**: 
  - Google đã chấm dứt hỗ trợ "Ứng dụng kém an toàn" (Less secure apps). Sử dụng mật khẩu tài khoản Gmail thông thường sẽ bị chặn.
  - Cấu hình sai cổng SMTP hoặc phương thức mã hóa (TLS/SSL).
- **Giải pháp khắc phục**:
  - Bật xác minh 2 bước trên tài khoản Google và khởi tạo **App Password** (Mật khẩu ứng dụng 16 ký tự).
  - Cấu hình chính xác trong `.env`:
    ```env
    MAIL_MAILER=smtp
    MAIL_HOST=smtp.gmail.com
    MAIL_PORT=587
    MAIL_ENCRYPTION=tls
    MAIL_USERNAME=your-email@gmail.com
    MAIL_PASSWORD=xxxx xxxx xxxx xxxx
    ```

### 5.2. Lỗi kết nối WebSocket (Laravel Reverb)
- **Triệu chứng / Báo lỗi**: Các tính năng cộng tác thời gian thực không hoạt động, console trình duyệt báo lỗi `WebSocket connection to 'ws://localhost:8080/...' failed`.
- **Nguyên nhân**: 
  - Service WebSocket chưa được khởi chạy ngầm.
  - Client cấu hình sai IP/Cổng của WebSocket server.
- **Giải pháp khắc phục**:
  - Trong Docker Compose, tách riêng một service `websocket` chạy lệnh `php artisan reverb:start --host=0.0.0.0 --port=8080`.
  - Trên Frontend, đảm bảo các file cấu hình Echo client kết nối đúng tới port 8080 và host tương ứng.

---

## 6. NHÓM LỖI GIAO DIỆN & TRẢI NGHIỆM NGười DÙNG

### 6.1. Lỗi giao diện bị che khuất bởi Fixed Navbar trên Mobile
- **Triệu chứng**: Trên màn hình điện thoại di động, thanh tiêu đề trang hoặc dòng đầu tiên của danh sách ghi chú bị thanh điều hướng (Navbar) đè lên, khiến người dùng không thể thao tác hoặc nhìn thấy nội dung.
- **Nguyên nhân**: Navbar được gán thuộc tính `position: fixed; top: 0;`. Thuộc tính này gỡ bỏ thanh điều hướng khỏi luồng hiển thị thông thường (normal flow), làm phần nội dung bên dưới bị đẩy lên sát đỉnh trang.
- **Giải pháp khắc phục**: Bổ sung đệm phía trên (padding-top) cho container chính hoặc thẻ `body` để bù đắp chiều cao của thanh điều hướng:
  ```css
  body {
      padding-top: 76px; /* Bằng đúng hoặc lớn hơn chiều cao của navbar */
  }
  ```

### 6.2. Lỗi Modal / Popup không đóng hoặc xám nền sau khi thao tác
- **Triệu chứng**: Sau khi thêm mới hoặc sửa ghi chú bằng Modal của Bootstrap 5, popup đã ẩn đi nhưng màn hình vẫn bị một lớp phủ màu xám (backdrop) ngăn cản thao tác.
- **Nguyên nhân**: Xung đột giữa việc đóng Modal bằng JavaScript (`modal.hide()`) và việc trang load/render lại một phần thông qua AJAX/Livewire mà lớp backdrop chưa kịp gỡ bỏ khỏi DOM.
- **Giải pháp khắc phục**: Xử lý triệt để trong đoạn mã JavaScript sau khi thao tác thành công:
  ```javascript
  const modalEl = document.getElementById('myModal');
  const modalInstance = bootstrap.Modal.getInstance(modalEl);
  if (modalInstance) {
      modalInstance.hide();
  }
  // Gỡ bỏ hoàn toàn lớp backdrop nếu còn sót lại
  document.querySelectorAll('.modal-backdrop').forEach(el => el.remove());
  document.body.classList.remove('modal-open');
  document.body.style.overflow = 'auto';
  ```

---

> [!TIP]
> Việc ghi nhận và giải quyết triệt để các lỗi trên không chỉ giúp hệ thống chạy ổn định, mượt mà mà còn là minh chứng rõ nét cho năng lực làm việc nhóm, khả năng giải quyết vấn đề (troubleshooting) và kiến thức vững vàng về Containerization (Docker) của nhóm thực hiện.

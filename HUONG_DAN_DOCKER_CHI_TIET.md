# 🐳 HƯỚNG DẪN NGHIÊN CỨU & TRIỂN KHAI DOCKER DESKTOP
## Chuyên đề: Containerization & Orchestration — Kiến trúc Multi-Tier (Topic 10)

> [!IMPORTANT]
> Tài liệu này được biên soạn nhằm hướng dẫn chi tiết cách thức thiết lập, vận hành và nghiên cứu chuyên sâu về Docker & Docker Compose áp dụng vào dự án **Note Management Application**. Đây là cẩm nang toàn diện giúp giảng viên và sinh viên nắm vững nguyên lý hoạt động của các container độc lập trong một hệ thống phân tán (Multi-tier).

---

## 📖 MỤC LỤC

1. [Tổng quan về Topic 10 & Kiến trúc Multi-Tier Containerization](#1-tổng-quan-về-topic-10--kiến-trúc-multi-tier)
2. [Cài đặt & Thiết lập Docker Desktop tối ưu](#2-cài-đặt--thiết-lập-docker-desktop)
3. [Vận hành dự án thực tế với một câu lệnh duy nhất](#3-vận-hành-dự-án-thực-tế-với-docker-compose)
4. [Nghiên cứu chuyên sâu: Phân tích chi tiết các file cấu hình](#4-nghiên-cứu-chuyên-sâu-các-file-cấu-hình)
5. [Quản trị, Giám sát và Gỡ lỗi (Troubleshooting)](#5-quản-trị-giám-sát-và-gỡ-lỗi)
6. [So sánh Kiến trúc Container vs Máy chủ truyền thống (XAMPP)](#6-so-sánh-kiến-trúc-container-vs-máy-chủ-truyền-thống)

---

## 1. TỔNG QUAN VỀ TOPIC 10 & KIẾN TRÚC MULTI-TIER

### 1.1. Khái niệm Containerization & Orchestration
- **Containerization (Đóng gói ứng dụng)**: Là công nghệ ảo hóa cấp hệ điều hành, cho phép đóng gói ứng dụng cùng toàn bộ thư viện, cấu hình và môi trường chạy vào một đơn vị độc lập gọi là Container. Tránh tình trạng *"Chạy được trên máy tôi nhưng lỗi trên máy khác"*.
- **Orchestration (Điều phối dịch vụ)**: Là quá trình quản lý, cấu hình và điều phối nhiều container làm việc cùng nhau. Trong dự án này, chúng ta sử dụng **Docker Compose** làm công cụ orchestration.

### 1.2. Sơ đồ Kiến trúc Hệ thống (Multi-Tier)
Hệ thống được thiết kế theo mô hình vi dịch vụ (microservices) với 4 thành phần tách biệt hoàn toàn:

```mermaid
graph TD
    subgraph Mạng nội bộ cô lập - Docker Network (note_network)
        A[note_app_web <br> PHP 8.2 + Apache + Laravel] --- B[(note_app_db <br> PostgreSQL 15)]
        A --- C[note_app_redis <br> Redis Cache & Session]
        A --- D[note_app_ws <br> Laravel Reverb WebSocket]
    end
    Client[Trình duyệt Web] -->|HTTP:8000| A
    Client -->|WS:8080| D
```

| Service | Tên Container | Chức năng & Công nghệ | Cổng Lắng nghe |
|---|---|---|---|
| **app** | `note_app_web` | Chạy ứng dụng Web (Frontend Blade + Backend API Laravel 11/12). | `8000:80` |
| **db** | `note_app_db` | Quản trị CSDL chính (PostgreSQL 15 Alpine). | `5433:5432` |
| **redis** | `note_app_redis`| Lưu trữ phiên làm việc (Session) và đệm dữ liệu (RAM Cache). | `6379:6379` |
| **websocket** | `note_app_ws` | Xử lý các kết nối cộng tác thời gian thực (Laravel Reverb). | `8080:8080` |

---

## 2. CÀI ĐẶT & THIẾT LẬP DOCKER DESKTOP

### 2.1. Yêu cầu & Cài đặt phần mềm
1. Truy cập trang chủ Docker: [Tải Docker Desktop](https://www.docker.com/products/docker-desktop/).
2. Trong quá trình cài đặt trên Windows, hãy chọn sử dụng **WSL 2 backend** (Windows Subsystem for Linux) thay vì Hyper-V để đạt hiệu suất tối ưu và tiết kiệm RAM.
3. Sau khi cài đặt, mở Docker Desktop và đảm bảo biểu tượng con cá voi ở góc dưới bên trái chuyển sang màu **Xanh lá** (Engine running).

### 2.2. Tránh xung đột cổng với XAMPP
> [!WARNING]
> Nếu máy tính của bạn đang chạy XAMPP hoặc các dịch vụ khác (Apache, MySQL, PostgreSQL local), hãy mở XAMPP Control Panel và nhấn **STOP** các dịch vụ này để giải phóng cổng `80`, `3306`, `5432`.

---

## 3. VẬN HÀNH DỰ ÁN THỰC TẾ VỚI DOCKER COMPOSE

### 3.1. Khởi chạy toàn bộ hệ thống (One-command Startup)
Mở Terminal (Command Prompt hoặc PowerShell) tại thư mục chứa mã nguồn dự án:

```bash
docker-compose up -d --build
```

**Giải thích các cờ (flags):**
- `up`: Lệnh khởi tạo và chạy các container được định nghĩa trong `docker-compose.yml`.
- `-d` (detached mode): Chạy các container ngầm trong nền, trả lại Terminal để bạn có thể tiếp tục gõ các lệnh khác.
- `--build`: Ép buộc Docker xây dựng lại (rebuild) image `note_app_web` dựa trên `Dockerfile` hiện tại. (Rất cần thiết cho lần chạy đầu hoặc khi có thay đổi code/cấu hình).

### 3.2. Kiểm tra trạng thái hệ thống
Sau khoảng 1 - 2 phút (khi quá trình build và tải image hoàn tất), gõ lệnh:

```bash
docker ps
```
Kết quả hiển thị 4 container với trạng thái (Status) là `Up` và phần `PORTS` ánh xạ chính xác:
- `0.0.0.0:8000->80/tcp` (`note_app_web`)
- `0.0.0.0:5433->5432/tcp` (`note_app_db`)
- `0.0.0.0:6379->6379/tcp` (`note_app_redis`)
- `0.0.0.0:8080->8080/tcp` (`note_app_ws`)

### 3.3. Khởi tạo dữ liệu mẫu (Seeding)
Trong lần khởi chạy đầu tiên, mặc dù CSDL đã tự động được tạo, bạn nên chạy thêm lệnh seed để nạp 2 tài khoản demo dùng thử:

```bash
docker exec -it note_app_web php artisan db:seed --force
```
- `docker exec -it <container_name>`: Mở phiên làm việc tương tác bên trong container.

### 3.4. Truy cập ứng dụng
Mở trình duyệt web bất kỳ và truy cập:
```text
http://localhost:8000
```
Đăng nhập với các tài khoản demo: `demo@example.com` / `123456` hoặc `demo2@example.com` / `123456`.

---

## 4. NGHIÊN CỨU CHUYÊN SÂU: CÁC FILE CẤU HÌNH

### 4.1. Phân tích `Dockerfile` (Xây dựng Image Ứng dụng)
File `Dockerfile` của dự án sử dụng chiến lược đa bước (multi-stage) và tối ưu hóa hệ điều hành:

```dockerfile
FROM php:8.2-apache
```
- Sử dụng Image chính thức của PHP 8.2 tích hợp sẵn web server Apache.

```dockerfile
RUN apt-get update && apt-get install -y libpq-dev libpng-dev libzip-dev zip unzip git curl \
    && docker-php-ext-install pdo_pgsql pgsql gd zip \
    && pecl install redis && docker-php-ext-enable redis ...
```
- Cài đặt các gói thư viện C++ hệ thống cần thiết cho PostgreSQL (`libpq-dev`), xử lý ảnh (`libpng-dev`).
- Biên dịch các module PHP mở rộng: `pdo_pgsql` (để giao tiếp PostgreSQL), `gd` (cắt xén ảnh avatar), và PECL `redis`.

```dockerfile
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
```
- Sử dụng tính năng multi-stage build, mượn file thực thi `composer` từ image chính thức của Composer sang mà không cần cài đặt cồng kềnh.

```dockerfile
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf
```
- Sửa đổi cấu hình Apache: Trỏ thư mục gốc (Document Root) thẳng vào `public/` của Laravel nhằm tăng cường bảo mật (tránh lộ các file hệ thống và cấu hình bên ngoài).

### 4.2. Phân tích `docker-compose.yml` (Điều phối Dịch vụ)
Đây là "trái tim" điều phối hệ thống. Các điểm nhấn kỹ thuật quan trọng bao gồm:

```yaml
depends_on:
  db:
    condition: service_healthy
```
- **Ràng buộc khởi động (Health Check Dependency)**: Service `app` sẽ không chạy ngay, mà kiên nhẫn chờ đến khi service `db` vượt qua bài kiểm tra sức khỏe (`pg_isready`) thành công.

```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data
```
- **Dữ liệu bền vững (Persistent Volumes)**: Ánh xạ thư mục dữ liệu bên trong container CSDL ra một vùng lưu trữ riêng do Docker quản lý. Nhờ đó, ngay cả khi bạn xóa container (`docker-compose down`), dữ liệu ghi chú của người dùng vẫn được bảo toàn nguyên vẹn.

```yaml
networks:
  - note_network
```
- **Cô lập mạng (Network Isolation)**: Tạo một mạng Bridge ảo nội bộ. Các container giao tiếp trực tiếp với nhau thông qua tên service (ví dụ `db`, `redis`) mà không cần biết IP cụ thể, đồng thời ngăn chặn các truy cập trái phép từ bên ngoài mạng.

### 4.3. Phân tích `docker-entrypoint.sh` (Tự động hóa Runtime)
Script thực thi mỗi khi container web khởi động:
1. **Quản lý biến PORT động**: Cho phép tương thích cả với môi trường Cloud (Railway).
2. **Kiểm tra và cài đặt Vendor**: Tự động chạy `composer install` nếu thư mục chưa tồn tại.
3. **Chờ đợi CSDL**: Vòng lặp 30 giây kiểm tra kết nối PostgreSQL.
4. **Tự động hóa Migration**: Chạy các file migrate và tạo symbolic link cho thư mục ảnh.

---

## 5. QUẢN TRỊ, GIÁM SÁT VÀ GỠ LỖI

### 5.1. Xem nhật ký hoạt động (Logs)
Để theo dõi các lỗi hoặc quá trình thực thi của các dịch vụ, dùng lệnh:
```bash
# Xem log toàn bộ hệ thống (trực tiếp)
docker-compose logs -f

# Xem log của riêng một dịch vụ
docker-compose logs -f app
docker-compose logs -f websocket
```

### 5.2. Chui vào bên trong Container để kiểm tra
Nếu cần chạy các lệnh thủ công (như clear cache, kiểm tra route):
```bash
docker exec -it note_app_web bash

# Sau khi vào bên trong container:
php artisan config:clear
php artisan route:list
exit
```

### 5.3. Dừng và dọn dẹp hệ thống
```bash
# Dừng và xóa container, giữ lại dữ liệu CSDL
docker-compose down

# Dừng, xóa container và XÓA SẠCH toàn bộ dữ liệu CSDL (Reset từ đầu)
docker-compose down -v
```

---

## 6. SO SÁNH KIẾN TRÚC CONTAINER VS MÁY CHỦ TRUYỀN THỐNG

| Tiêu chí | Máy chủ truyền thống / XAMPP | Đóng gói Container (Docker) |
|---|---|---|
| **Độ phức tạp khi Setup** | Phải cài từng phần mềm (PHP, Apache, MySQL), dễ xung đột phiên bản. | Chỉ cần cài Docker, chạy 1 câu lệnh duy nhất. |
| **Tính đồng nhất** | Dễ gặp lỗi *"Chạy ở máy tôi nhưng lỗi ở máy bạn"*. | Môi trường đồng nhất tuyệt đối từ Dev đến Production. |
| **Tách biệt Dịch vụ** | Tất cả chạy chung trên 1 hệ điều hành, nếu 1 dịch vụ sập có thể kéo theo toàn hệ thống. | Tách biệt hoàn toàn (Web, DB, Cache, WS chạy ở các container riêng). |
| **Tốc độ Triển khai** | Tốn hàng giờ để cấu hình server mới. | Vài phút để pull image và chạy. |
| **Tính bảo mật** | Dễ bị tấn công leo thang đặc quyền từ web sang DB. | Mạng nội bộ bị cô lập, chỉ mở cổng cần thiết ra ngoài. |

> [!TIP]
> Việc làm chủ công nghệ Docker giúp bạn dễ dàng đưa dự án này lên các hệ thống cloud hiện đại (AWS, Google Cloud, Railway), đồng thời ghi điểm tuyệt đối trong mắt giảng viên chấm đề tài Topic 10.

# 🛠️ Hướng dẫn thực hiện Topic 10: Containerization & Orchestration (Docker)

Báo cáo này hướng dẫn chi tiết cách triển khai dự án **Note Management** theo đúng yêu cầu của Topic 10 trong đề bài Tiểu luận giữa kỳ.

---

## 1. Phân tích yêu cầu Topic 10
Đề bài yêu cầu:
- **Công nghệ**: Docker, Docker Compose, Microservices, Container Isolation.
- **Thành phần**: Multi-tier app bao gồm **Frontend**, **Backend API**, **Redis**, và **PostgreSQL**.
- **Điều kiện**: Chạy toàn bộ hệ thống bằng một câu lệnh duy nhất `docker-compose up`.

## 2. Kiến trúc hệ thống (Multi-tier)
Hệ thống được thiết kế gồm 4 Service chính chạy trong các Container riêng biệt:

| Service | Vai trò | Công nghệ |
| :--- | :--- | :--- |
| **App (Web)** | Frontend + Backend API | PHP 8.2 + Apache + Laravel |
| **Database** | Lưu trữ dữ liệu | PostgreSQL 15 |
| **Cache** | Session & Cache (Tăng tốc) | Redis Alpine |
| **WebSocket** | Real-time Collaboration | Laravel Reverb |

## 3. Các File cấu hình đã tạo

### 🔹 `Dockerfile`
File này chứa các chỉ dẫn để đóng gói ứng dụng Laravel. 
- Sử dụng Image `php:8.2-apache`.
- Cài đặt các extension cần thiết cho PostgreSQL (`pdo_pgsql`) và Redis.
- Tự động cài đặt Composer và phân quyền thư mục.

### 🔹 `docker-compose.yml`
File này điều phối (orchestration) cả 4 service.
- **Isolation**: Các container nằm trong một mạng nội bộ riêng (Docker network).
- **Persistence**: Sử dụng `volumes` để lưu trữ dữ liệu PostgreSQL ngay cả khi container bị xóa.
- **Dependencies**: Đảm bảo Database và Redis khởi động trước ứng dụng.

### 🔹 `docker-entrypoint.sh`
Script tự động chạy mỗi khi khởi động container:
- `composer install`: Cài đặt thư viện.
- `php artisan migrate`: Tự động tạo bảng trong PostgreSQL.
- `php artisan storage:link`: Tạo link cho file ảnh.

---

## 4. Hướng dẫn triển khai chi tiết

### Bước 1: Chuẩn bị môi trường
- Cài đặt **Docker Desktop** (nếu chưa có): [Download tại đây](https://www.docker.com/products/docker-desktop/).
- Đảm bảo đã tắt XAMPP (đặc biệt là Apache/MySQL nếu trùng port).

### Bước 2: Khởi động hệ thống
Mở Terminal (CMD hoặc PowerShell) tại thư mục dự án và chạy:

```bash
docker-compose up -d --build
```

- `-d`: Chạy ngầm (background).
- `--build`: Xây dựng lại Image (cần cho lần đầu hoặc khi sửa Dockerfile).

### Bước 3: Kiểm tra trạng thái
```bash
docker ps
```
Bạn sẽ thấy 4 container: `note_app_web`, `note_app_db`, `note_app_redis`, `note_app_ws` đều đang ở trạng thái **Up**.

### Bước 4: Truy cập ứng dụng
Mở trình duyệt: `http://localhost:8000`

---

## 5. Giải thích các điểm kỹ thuật để đưa vào Báo cáo (Report)

### Tại sao chọn PostgreSQL thay vì MySQL?
Theo yêu cầu chính xác của Topic 10 trong PDF, hệ thống phải sử dụng **PostgreSQL**. Đây là một hệ quản trị CSDL quan hệ mạnh mẽ, hỗ trợ tốt các kiểu dữ liệu phức tạp (JSONB) và thường được ưu tiên trong các hệ thống microservices hiện đại.

### Vai trò của Redis trong Multi-tier
Redis đóng vai trò là tầng **Cache** và **Session store**. Thay vì lưu session vào Database hoặc File (chậm), chúng ta lưu vào RAM (Redis) giúp tốc độ phản hồi của API cực nhanh, thỏa mãn tiêu chí "Multi-tier architecture".

### Container Isolation
Mỗi service (App, DB, Redis) chạy trong một môi trường bị cô lập hoàn toàn. Chúng chỉ có thể giao tiếp với nhau qua tên service (ví dụ: host của DB là `db` thay vì `localhost`). Điều này giúp bảo mật cao hơn.

---

## 6. Kiểm tra lỗi (Health Check)
Tôi đã kiểm tra mã nguồn và thấy:
- **Logic**: Các Controller và Model đã sẵn sàng cho PostgreSQL (Laravel Eloquent tự động chuyển đổi SQL).
- **Socket**: Đã cấu hình Laravel Reverb để chạy mượt mà trong Docker.
- **PWA**: File `manifest.json` và `sw.js` đã sẵn sàng để ứng dụng có thể cài đặt trên điện thoại/máy tính.

---
*Chúc nhóm bạn hoàn thành tốt báo cáo giữa kỳ!*

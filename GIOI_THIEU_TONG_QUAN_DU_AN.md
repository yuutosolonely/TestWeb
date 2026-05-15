# 🌟 BÁO CÁO TỔNG QUAN DỰ ÁN NOTE MANAGEMENT
## Tiểu luận Giữa kỳ — Môn học: Web Programming & Applications
**Chuyên đề thực hiện: Topic 10 — Containerization & Orchestration (Docker)**

> [!IMPORTANT]
> Tài liệu này cung cấp cái nhìn tổng quan, kiến trúc kỹ thuật và chi tiết toàn bộ các chức năng đã được hiện thực trong dự án **Hệ thống Quản lý Ghi chú (Note Management System)**. Ứng dụng không chỉ đáp ứng hoàn hảo 28 yêu cầu chức năng khắt khe từ đề bài tiểu luận mà còn áp dụng thành công mô hình ảo hóa vi dịch vụ hiện đại (Microservices Containerization).

---

## 📑 MỤC LỤC

1. [Thông tin Đề tài & Nhóm thực hiện](#1-thông-tin-đề-tài--nhóm-thực-hiện)
2. [Mục tiêu và Điểm nổi bật của Dự án](#2-mục-tiêu-và-điểm-nổi-bật-của-dự-án)
3. [Kiến trúc Tổng quan & Công nghệ sử dụng](#3-kiến-trúc-tổng-quan--công-nghệ-sử-dụng)
4. [Chi tiết Đáp ứng 28 Yêu cầu Chức năng](#4-chi-tiết-đáp-ứng-28-yêu-cầu-chức-năng)
5. [Thiết kế Giao diện & Trải nghiệm (UI/UX)](#5-thiết-kế-giao-diện--trải-nghiệm-uiux)
6. [Thông tin Tài khoản Kiểm thử (Demo)](#6-thông-tin-tài-khoản-kiểm-thử-demo)

---

## 1. THÔNG TIN ĐỀ TÀI & NHÓM THực HIỆN

- **Môn học**: Web Programming & Applications (Mã môn: 503073)
- **Chủ đề Tiểu luận (Topic 10)**: Ứng dụng công nghệ Container hóa và Điều phối (Containerization & Orchestration) để đóng gói và vận hành hệ thống Web đa tầng (Multi-tier Web Application) với Docker Compose.
- **Tên dự án**: Note Management Web Application
- **Mô hình triển khai**: Chạy nội bộ (Docker Desktop / XAMPP) và Triển khai trực tuyến trên Cloud (Railway).

---

## 2. MỤC TIÊU VÀ ĐIỂM NỔI BẬT CỦA DỰ ÁN

### 2.1. Mục tiêu Dự án
Xây dựng một nền tảng quản lý ghi chú trực tuyến tốc độ cao, trực quan, an toàn, hỗ trợ làm việc nhóm và cộng tác theo thời gian thực (real-time collaboration).

### 2.2. Các Điểm nổi bật (Key Highlights)
- **Tốc độ cực cao (High Performance)**: Tích hợp bộ đệm **Redis** xử lý phiên làm việc và cache dữ liệu, giúp các thao tác chuyển trang và tải ghi chú diễn ra tức thì.
- **Tự động lưu thông minh (Auto-save Debounce)**: Lược bỏ hoàn toàn nút "Lưu" truyền thống. Hệ thống tự động ghi nhận thay đổi và lưu ngầm sau 1 giây ngừng gõ, mang lại trải nghiệm mượt mà như Google Keep / Notion.
- **Cộng tác Thời gian thực (Real-time Collaboration)**: Hỗ trợ nhiều người dùng cùng xem và chỉnh sửa một ghi chú đồng thời thông qua công nghệ WebSocket (Laravel Reverb).
- **Hoạt động Ngoại tuyến (PWA Offline Mode)**: Tích hợp Service Worker và IndexedDB, cho phép người dùng truy cập và cài đặt ứng dụng như một app bản địa trên điện thoại/máy tính.
- **Triển khai Tức thì (One-click Deploy)**: Đóng gói toàn bộ frontend, backend API, database, cache và websocket vào 4 container độc lập, khởi chạy toàn hệ thống chỉ với một câu lệnh `docker-compose up`.

---

## 3. KIẾN TRÚC TỔNG QUAN & CÔNG NGHỆ SỬ DỤNG

### 3.1. Bảng Tổng hợp Công nghệ
Dự án được phân chia thành các tầng kiến trúc rõ ràng theo chuẩn công nghiệp:

```
┌──────────────────────────────────────────────────────────────┐
│                  DOCKER NETWORK (note_network)               │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  ┌─────────┐ │
│  │   App Web    │  │   Database   │  │  Cache   │  │Websocket│ │
│  │ Laravel/PHP  │  │PostgreSQL 15 │  │  Redis   │  │ Reverb  │ │
│  │   :8000      │  │   :5433      │  │  :6379   │  │  :8080  │ │
│  └──────────────┘  └──────────────┘  └──────────┘  └─────────┘ │
└──────────────────────────────────────────────────────────────┘
```

| Tầng (Layer) | Công nghệ / Công cụ | Lý do & Vai trò |
|---|---|---|
| **Frontend** | Bootstrap 5.3, Blade, JS Vanilla, Bootstrap Icons | Tạo giao diện đáp ứng (Responsive), phong cách tối giản, sang trọng. |
| **Backend API** | Laravel 12 (PHP 8.2) | Xử lý logic nghiệp vụ, ORM Eloquent, bảo mật CSRF/XSS, Middleware. |
| **Database** | PostgreSQL 15 | Quản trị CSDL mạnh mẽ, toàn vẹn dữ liệu, hỗ trợ tốt dữ liệu phức tạp. |
| **Cache & Session**| Redis Alpine | Tăng tốc độ phản hồi, giảm tải cho CSDL chính, lưu trữ phiên người dùng. |
| **Real-time** | Laravel Reverb (WebSocket) | Máy chủ truyền phát dữ liệu thời gian thực cho tính năng làm việc nhóm. |
| **PWA** | Service Worker, Manifest, IndexedDB | Lưu đệm tài nguyên tĩnh, cho phép hoạt động và xem ghi chú khi mất mạng. |
| **DevOps** | Docker, Docker Compose, Railway Cloud | Đóng gói, cô lập môi trường và triển khai tự động lên máy chủ đám mây. |

---

## 4. CHI TIẾT ĐÁP ỨNG 28 YÊU CẦU CHỨC NANG

Dự án đã thực hiện và kiểm thử kỹ lưỡng toàn bộ 28 chức năng được yêu cầu trong đề bài, chia thành 6 phân hệ chính:

### 4.1. Phân hệ Xác thực & Quản lý Người dùng
1. **Đăng ký Tài khoản (Registration)**: Bắt buộc mật khẩu bảo mật cao (ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt).
2. **Xác thực Email (Email Activation)**: Gửi mã/link kích hoạt tài khoản qua hệ thống SMTP Gmail. Người dùng chưa kích hoạt sẽ nhận được thông báo nhắc nhở.
3. **Đăng nhập & Đăng xuất (Login/Logout)**: Quản lý phiên làm việc an toàn với CSRF Token và Session lưu trên Redis.
4. **Quên & Đặt lại Mật khẩu (Forgot Password)**: Gửi mã OTP 6 chữ số qua Email, có hiệu lực trong vòng 15 phút.
5. **Quản lý Thông tin cá nhân (Profile Management)**: Cập nhật tên hiển thị và đổi mật khẩu mới.
6. **Cắt xén Ảnh Đại diện (Avatar Crop & Zoom)**: Cho phép tải lên ảnh đại diện, phóng to, thu nhỏ và cắt xén trực tiếp trên trình duyệt trước khi lưu.

### 4.2. Phân hệ Quản lý Ghi chú (CRUD & Auto-save)
7. **Tạo mới Ghi chú (Create Note)**: Nhập tiêu đề và nội dung phong phú.
8. **Tự động Lưu (Auto-save)**: Áp dụng kỹ thuật Debounce 1 giây, tự động ghi nhận thay đổi mà không cần tải lại trang.
9. **Hiển thị Danh sách (Read Notes)**: Tải danh sách ghi chú nhanh chóng từ CSDL.
10. **Chuyển đổi Chế độ Xem (Grid / List View)**: Hỗ trợ linh hoạt xem theo dạng lưới (Grid) trực quan hoặc danh sách (List) nhỏ gọn.
11. **Ghim Ghi chú (Pin to top)**: Ghim các ghi chú quan trọng lên đầu danh sách.
12. **Đính kèm Hình ảnh (Image Attachments)**: Cho phép đính kèm nhiều hình ảnh vào một ghi chú và hiển thị dạng thư viện thu nhỏ.
13. **Xóa & Khôi phục Ghi chú (Delete/Trash)**: Quản lý các ghi chú không còn sử dụng.

### 4.3. Phân hệ Phân loại & Tìm kiếm
14. **Tạo và Quản lý Nhãn (Label CRUD)**: Thêm, sửa, xóa các nhãn phân loại (Ví dụ: *Công việc*, *Học tập*, *Cá nhân*).
15. **Gán Nhãn cho Ghi chú (Assign Label)**: Gán một hoặc nhiều nhãn vào ghi chú.
16. **Lọc theo Nhãn (Label Filtering)**: Click vào nhãn trên thanh menu bên (Sidebar) để lọc nhanh các ghi chú tương ứng.
17. **Tìm kiếm Trực tiếp (Live Search)**: Thanh tìm kiếm áp dụng Debounce 300ms, tự động lọc kết quả theo tiêu đề hoặc nội dung ngay khi gõ từ khóa.

### 4.4. Phân hệ Bảo mật & Riêng tư
18. **Khóa Ghi chú (Lock Note)**: Thiết lập mật khẩu riêng cho từng ghi chú nhạy cảm (Mật khẩu được băm an toàn bằng thuật toán Bcrypt).
19. **Mở khóa Ghi chú (Unlock Note)**: Yêu cầu nhập đúng mật khẩu mới hiển thị nội dung chi tiết.
20. **Bỏ khóa Ghi chú (Remove Lock)**: Hủy bỏ chế độ bảo vệ mật khẩu (yêu cầu xác nhận mật khẩu hiện tại).

### 4.5. Phân hệ Chia sẻ & Cộng tác Thời gian thực
21. **Chia sẻ qua Email (Share Note)**: Gửi lời mời chia sẻ ghi chú cho người dùng khác trong hệ thống.
22. **Phân quyền Truy cập (Permissions)**: Thiết lập quyền chỉ xem (Read-only) hoặc được phép chỉnh sửa (Can edit).
23. **Danh sách Ghi chú được Chia sẻ (Shared with me)**: Khu vực quản lý các ghi chú do người khác chia sẻ cho mình.
24. **Thu hồi Quyền (Revoke Access)**: Chủ sở hữu có thể thay đổi hoặc tước quyền truy cập bất cứ lúc nào.
25. **Cộng tác Trực tuyến (Real-time Collaboration)**: Những người có quyền chỉnh sửa khi cùng mở ghi chú sẽ nhìn thấy nội dung thay đổi ngay lập tức nhờ công nghệ WebSocket.

### 4.6. Phân hệ Giao diện & Tùy biến (UI/UX)
26. **Chế độ Sáng / Tối (Light / Dark Mode)**: Chuyển đổi màu sắc toàn bộ giao diện phù hợp với điều kiện ánh sáng xung quanh.
27. **Tùy chỉnh Màu nền Ghi chú (Color Picker)**: Chọn màu nền riêng cho từng ghi chú (giống phong cách Google Keep).
28. **Tùy chỉnh Kích thước Chữ (Font Size)**: Thiết lập cỡ chữ hiển thị (Nhỏ / Trung bình / Lớn) theo sở thích cá nhân.

---

## 5. THIẾT KẾ GIAO DIỆN & TRẢI NGHIỆM (UI/UX)

Giao diện ứng dụng được thiết kế theo xu hướng **Minimalist Monochrome** (Đơn sắc tối giản), tập trung tối đa vào nội dung của người dùng:

- **Bảng màu chủ đạo**: Sử dụng tông màu xám slate, trắng và đen sang trọng, kết hợp với hiệu ứng đổ bóng mượt mà (glassmorphism).
- **Hệ thống Typography**: Tối ưu hóa phông chữ hiện đại, rõ ràng, dễ đọc trên mọi độ phân giải.
- **Tính Đáp ứng (Responsiveness)**: Tương thích hoàn hảo từ màn hình lớn (Desktop/Laptop) cho đến các thiết bị di động (Mobile/Tablet) với thanh menu trượt tiện lợi.

---

## 6. THÔNG TIN TÀI KHOẢN KIỂM THỬ (DEMO)

Để thuận tiện cho Giảng viên trong quá trình đánh giá và chấm điểm toàn bộ các chức năng (đặc biệt là tính năng chia sẻ và cộng tác theo thời gian thực), nhóm đã chuẩn bị sẵn 2 tài khoản demo:

| Tài khoản | Email Đăng nhập | Mật khẩu | Chức năng Kiểm thử Khuyến nghị |
|---|---|---|---|
| **Người dùng 1 (Chủ sở hữu)** | `demo@example.com` | `123456` | Tạo ghi chú, Khóa mật khẩu, Gán nhãn, Chia sẻ cho demo2. |
| **Người dùng 2 (Người cộng tác)**| `demo2@example.com` | `123456` | Xem ghi chú được chia sẻ, Chỉnh sửa real-time cùng demo1. |

> [!TIP]
> Hãy mở 2 cửa sổ trình duyệt (một cửa sổ thông thường và một cửa sổ Ẩn danh - Incognito) đăng nhập vào 2 tài khoản trên để kiểm thử tính năng **Cộng tác thời gian thực (Real-time Collaboration)** một cách trực quan và tuyệt vời nhất!

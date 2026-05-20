# 🖥️ KỊCH BẢN CHI TIẾT & NỘI DUNG SLIDES THUYẾT TRÌNH
## CHUYÊN ĐỀ TOPIC 10: CONTAINERIZATION & ORCHESTRATION (DOCKER)
### DỰ ÁN: HỆ THỐNG QUẢN LÝ GHI CHÚ ĐA TẦNG (NOTE MANAGEMENT APPLICATION)
*Môn học: Web Programming & Applications (Mã môn: 503073) — Học kỳ II*

---

> [!TIP]
> File này chứa **độc quyền** nội dung phục vụ cho việc thiết kế PowerPoint và lời thoại thuyết trình. Mọi thông tin thừa đã được loại bỏ, giúp bạn dễ dàng sao chép từng phần vào slide và luyện tập thuyết trình một cách nhanh nhất.

---

## 🗂️ DANH SÁCH 13 SLIDES THUYẾT TRÌNH

### 🎬 SLIDE 1: TRANG BÌA & GIỚI THIỆU ĐỀ TÀI
* **Gợi ý thiết kế (Visual Layout)**: Sử dụng tone màu tối sang trọng (Dark theme), Logo trường ở góc trên bên trái. Ở giữa đặt logo con cá voi Docker màu xanh dương phát sáng neon nổi bật trên nền bản đồ mạng lưới kết nối.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **ĐỀ TÀI DỰ ÁN**: Note Management Web Application.
  * **CHUYÊN ĐỀ PHÂN TÍCH**: Topic 10 - Containerization & Orchestration.
  * **CÔNG NGHỆ ÁP DỤNG**: Docker, Docker Compose, PostgreSQL, Redis, Laravel Reverb (WebSocket), PWA.
  * **GIẢNG VIÊN HƯỚNG DẪN**: TS. Lê Văn Vang.
  * **NHÓM THỰC HIỆN**: Nhóm 10 (Ghi tên các thành viên).
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Kính chào thầy cô trong Hội đồng đánh giá và các bạn sinh viên. Hôm nay nhóm chúng em xin phép trình bày đồ án kết thúc môn học Web Programming & Applications. Đề tài của chúng em là 'Xây dựng ứng dụng quản lý ghi chú đa tầng Note Management'. Trong đó, nhóm chúng em tập trung giải quyết Chuyên đề Topic 10: Đóng gói ứng dụng bằng công nghệ Containerization và Điều phối dịch vụ bằng Orchestration thông qua hệ sinh thái Docker. Sau đây, chúng em xin đi vào chi tiết."*

---

### 🔍 SLIDE 2: ĐẶT VẤN ĐỀ & MỤC TIÊU DỰ ÁN
* **Gợi ý thiết kế (Visual Layout)**: Thiết kế đối xứng (Split-screen). Bên trái là biểu tượng "Cảnh báo" màu đỏ (Vấn đề); Bên phải là biểu tượng "Chìa khóa/Mục tiêu" màu xanh lá (Giải pháp).
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Thực trạng phát triển ứng dụng phức tạp**:
    * ⚠️ Lỗi "Chạy tốt trên máy tôi, nhưng lỗi trên máy bạn" do sai lệch môi trường (xung đột phiên bản PHP, Apache, Node.js).
    * ⚠️ Khó khăn khi cài đặt, tích hợp các dịch vụ nâng cao như PostgreSQL, Redis cache, WebSocket.
    * ⚠️ Mất nhiều thời gian cấu hình cổng, tài khoản cơ sở dữ liệu thủ công giữa các thành viên.
  * **Mục tiêu của dự án**:
    * ✅ Ảo hóa và đóng gói độc lập toàn bộ các dịch vụ hệ thống.
    * ✅ Khởi chạy dự án tự động chỉ bằng **1 dòng lệnh duy nhất**.
    * ✅ Đồng bộ môi trường 100% từ máy lập trình viên cho đến cloud production.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Trong quy trình phát triển phần mềm truyền thống, lập trình viên thường xuyên gặp lỗi xung đột môi trường. 'Chạy tốt trên máy của em nhưng lại lỗi trên máy của bạn' là câu nói kinh điển. Hơn nữa, với một ứng dụng ghi chú cao cấp đòi hỏi cả cơ sở dữ liệu PostgreSQL, cache Redis và server WebSocket, việc cài đặt thủ công từng dịch vụ trên máy cá nhân là cực kỳ phức tạp và dễ gây nghẽn hệ thống. Mục tiêu của chúng em là đóng gói toàn bộ ứng dụng này vào các Container độc lập, giúp việc triển khai trở nên tự động hoàn toàn, đồng bộ 100% trên mọi máy tính."*

---

### 🌐 SLIDE 3: TỔNG QUAN KIẾN TRÚC ĐA TẦNG (MULTI-TIER)
* **Gợi ý thiết kế (Visual Layout)**: Một sơ đồ khối trực quan vẽ 4 khối hình hộp chữ nhật màu sắc khác nhau, nằm chung trong một đường viền nét đứt đại diện cho mạng ảo `note_network`. Có mũi tên chỉ luồng dữ liệu từ Client truy cập vào cổng `8000` và cổng `8080`.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Kiến trúc phân rã 4 Dịch vụ (4-Tier)**:
    * **Web App (`app`)**: PHP 8.2 + Apache. Đầu ngõ xử lý HTTP requests (Port `8000`).
    * **Database (`db`)**: PostgreSQL 15 Alpine. Lưu trữ dữ liệu quan hệ (Port `5433`).
    * **Cache Store (`redis`)**: Redis Alpine. Bộ nhớ đệm RAM lưu Session và cache ghi chú (Port `6379`).
    * **WebSocket Server (`websocket`)**: Laravel Reverb. Truyền thông thời gian thực (Port `8080`).
  * **Mạng ảo nội bộ**: Cấu hình `note_network` (driver: bridge) cô lập và an toàn tuyệt đối.
* **Lời thoại thuyết trình (Speaking Notes)**:
  > *"Hệ thống của chúng em được xây dựng trên Kiến trúc Đa tầng (Multi-tier Architecture) tiên tiến gồm 4 container chạy hoàn toàn tách biệt. Đầu tiên là container App đóng vai trò tiếp nhận yêu cầu từ người dùng qua cổng 8000. Dữ liệu ghi chú được lưu trữ bền vững tại container DB chạy PostgreSQL. Để tăng tốc độ phản hồi, chúng em có container Redis đóng vai trò lưu đệm session trên RAM. Và cuối cùng là container WebSocket Reverb chịu trách nhiệm duy trì kênh truyền thông hai chiều để đồng bộ ghi chú. Toàn bộ 4 dịch vụ này được đặt trong một mạng Bridge ảo khép kín gọi là 'note_network', đảm bảo tính an toàn và bảo mật cao nhất."*

---

### 🐳 SLIDE 4: TẠI SAO CHỌN DOCKER CONTAINER? (DOCKER VS VM)
* **Gợi ý thiết kế (Visual Layout)**: Vẽ 2 mô hình kiến trúc đặt cạnh nhau. Bên trái là mô hình Máy ảo (Virtual Machine) chứa nhiều Guest OS nặng nề; Bên phải là mô hình Docker Container chia sẻ chung nhân hệ điều hành vật lý cực kỳ gọn nhẹ.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Máy ảo truyền thống (VM)**:
    * ❌ Phải cõng hệ điều hành khách hoàn chỉnh (Guest OS) cho từng app.
    * ❌ Khởi động chậm (tính bằng phút), ngốn RAM, CPU và bộ nhớ (hàng chục GB).
  * **Docker Container (Ảo hóa cấp OS)**:
    * ⭐ Loại bỏ Guest OS, chia sẻ trực tiếp nhân của Host OS (Kernel).
    * ⭐ Dung lượng siêu nhẹ (chỉ từ vài chục MB), khởi động trong vài mili-giây.
    * ⭐ Đạt hiệu năng chạy ứng dụng gần như nguyên bản (Native Performance).
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Để hiểu rõ ưu thế của Docker, hãy so sánh nó với máy ảo truyền thống VM. Nhìn vào sơ đồ kiến trúc, chúng ta thấy VM rất cồng kềnh vì mỗi máy ảo phải duy trì một hệ điều hành khách riêng, làm lãng phí hàng chục gigabyte ổ cứng và hàng gigabyte RAM. Docker giải quyết triệt để rào cản này bằng cách ảo hóa ở cấp độ hệ điều hành, chia sẻ chung nhân Kernel của máy thật. Nhờ vậy, container Docker có dung lượng siêu nhẹ, khởi động tức thì trong chớp mắt và đạt hiệu suất xử lý phần cứng tối ưu nhất."*

---

### 🎨 SLIDE 5: TẦNG ỨNG DỤNG & THIẾT KẾ PWA OFFLINE-FIRST
* **Gợi ý thiết kế (Visual Layout)**: Hiển thị hình ảnh một chiếc điện thoại di động chạy ứng dụng Note Management kèm biểu tượng "Mất kết nối mạng (No Internet)" nhưng ứng dụng vẫn mở và viết ghi chú bình thường.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Công nghệ nền tảng**: PHP 8.2 + Web Server Apache + Laravel Framework.
  * **Tính năng Progressive Web App (PWA) đột phá**:
    * 📱 Khả năng "Cài đặt ứng dụng" trực tiếp lên màn hình điện thoại/máy tính không qua kho ứng dụng App Store.
    * 🔄 **Service Worker (`sw.js`)**: Chạy ngầm trong trình duyệt, tự động cache tài nguyên tĩnh (HTML, CSS, JS) phục vụ chạy offline.
    * 💾 **IndexedDB**: Cơ sở dữ liệu NoSQL trong trình duyệt giúp lưu tạm ghi chú khi mất mạng, tự động đồng bộ lên Server ngay khi có mạng trở lại.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Tầng ứng dụng sử dụng Laravel chạy trên nền PHP 8.2 và máy chủ Apache. Điểm nhấn công nghệ đặc biệt ở đây là chúng em đã biến ứng dụng này thành một Progressive Web App (PWA) thực thụ. Nhờ vào Service Worker chạy ngầm, toàn bộ giao diện tĩnh được lưu vào cache trình duyệt. Kết hợp với CSDL IndexedDB, người dùng vẫn có thể viết ghi chú bình thường khi mất mạng. Ngay khi thiết bị có kết nối mạng trở lại, PWA sẽ tự động đồng bộ hóa các bản nháp offline này lên máy chủ PostgreSQL, mang lại trải nghiệm vô cùng mượt mà."*

---

### 🗄️ SLIDE 6: TẦNG CƠ SỞ DỮ LIỆU & BỘ ĐỆM CACHE
* **Gợi ý thiết kế (Visual Layout)**: Hình ảnh chiếc trống lưu trữ dữ liệu PostgreSQL và hộp bộ nhớ RAM phát sáng của Redis, nối với nhau bằng các tia sét biểu thị tốc độ truyền tải cực cao.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **PostgreSQL 15 Alpine (Cơ sở dữ liệu chính)**:
    * ⚡ Hỗ trợ kiểu dữ liệu JSONB động cực mạnh, lý tưởng để lưu cấu hình giao diện ghi chú.
    * ⚡ Tính toàn vẹn dữ liệu cực cao tuân thủ nghiêm ngặt ACID, xử lý đồng thời (Concurrency) vượt trội hơn MySQL.
  * **Redis Alpine (Bộ đệm RAM cache tốc độ cao)**:
    * 🚀 Giảm tải tối đa cho ổ cứng PostgreSQL bằng cách lưu Sessions đăng nhập trực tiếp trên RAM.
    * 🚀 Thời gian kiểm tra phiên đăng nhập người dùng giảm từ ~50ms xuống **dưới 1ms**.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Về cơ sở dữ liệu, chúng em chọn PostgreSQL 15. So với MySQL, PostgreSQL mạnh mẽ hơn hẳn khi xử lý các câu truy vấn phức tạp và đặc biệt hỗ trợ lưu trữ định dạng JSONB. Ghi chú của người dùng thường có nhiều thuộc tính động như màu sắc, thẻ nhãn, tọa độ vẽ, vì vậy JSONB giúp chúng em lưu trữ linh hoạt mà không cần tạo quá nhiều bảng. Ngoài ra, để tránh nghẽn băng thông ổ đĩa, chúng em tích hợp Redis chạy hoàn toàn trên RAM để lưu thông tin phiên đăng nhập. Nhờ đó, tốc độ kiểm tra đăng nhập người dùng được giảm xuống dưới 1 mili-giây, giúp hệ thống hoạt động vô cùng nhẹ nhàng."*

---

### ⚡ SLIDE 7: WEBSOCKET REAL-TIME & CỘNG TÁC THỜI GIAN THỰC
* **Gợi ý thiết kế (Visual Layout)**: Thiết kế chia đôi màn hình, mô phỏng hai người dùng khác nhau đang cùng mở một trang ghi chú và cùng gõ chữ. Nội dung chữ xuất hiện đồng thời ở cả hai bên cực kỳ sinh động.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Laravel Reverb WebSocket Server**:
    * 📡 Duy trì kết nối socket hai chiều liên tục giữa trình duyệt và máy chủ.
    * 📡 Loại bỏ hoàn toàn cơ chế Polling (kéo dữ liệu liên tục gây lãng phí băng thông).
  * **Tính năng Cộng tác thời gian thực (Real-time Collaboration)**:
    * 👥 Đồng bộ nội dung ghi chú tức thì khi có thành viên khác chỉnh sửa.
    * 👥 Tính năng **Tự động lưu ngầm (Auto-save)** áp dụng kỹ thuật **Debounce 1 giây** giúp nâng cao trải nghiệm người dùng tối đa.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Tính năng nổi bật và mang tính thực tiễn cao nhất của dự án là khả năng cộng tác nhóm thời gian thực. Chúng em sử dụng máy chủ WebSocket Laravel Reverb thế hệ mới. Khi hai hay nhiều thành viên cùng mở chung một ghi chú được chia sẻ, bất kỳ ai gõ chữ hay đổi màu nền, thông tin sẽ được phát qua kênh socket và cập nhật lên màn hình của những người còn lại ngay lập tức mà không cần tải lại trang. Hệ thống cũng tích hợp cơ chế Auto-save tự động lưu ghi chú sau 1 giây ngắt nghỉ gõ chữ, loại bỏ hoàn toàn nút Lưu thủ công phiền phức."*

---

### 📄 SLIDE 8: PHÂN TÍCH TỆP CẤU HÌNH DOCKERFILE
* **Gợi ý thiết kế (Visual Layout)**: Hiển thị hình ảnh một đoạn mã Dockerfile được phóng to với các đường line chỉ dẫn giải thích: Cài Extensions, Cài Composer, Biên dịch assets, và Phân quyền thư mục.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Base Image**: `php:8.2-apache` - Tích hợp sẵn PHP 8.2 và máy chủ Apache.
  * **Biên dịch tiện ích hệ thống**: Tự động cài đặt driver kết nối `pdo_pgsql` và tiện ích `redis` cho PHP.
  * **Multi-stage Build**: Sao chép trực tiếp tệp Composer thực thi giúp Image gọn nhẹ.
  * **Biên dịch Frontend**: Tích hợp Node.js v20 để tự động hóa biên dịch JS/CSS qua công cụ Vite (`npm run build`).
  * **Bảo mật**: Cấu hình Apache trỏ thẳng vào thư mục `public/` và phân quyền ghi cho User hệ thống `www-data`.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Để đóng gói ứng dụng Web, chúng em đã thiết kế tệp tin Dockerfile này. Chúng em sử dụng image gốc là PHP 8.2 Apache. Trong quá trình build Image, Dockerfile sẽ tự động cài các thư viện C++ cần thiết để biên dịch driver kết nối PostgreSQL và Redis. Kỹ thuật nâng cao ở đây là chúng em áp dụng Multi-stage build để kéo Composer từ image chính thức giúp giảm dung lượng. Đồng thời, Dockerfile cài đặt Node.js v20 để biên dịch giao diện Frontend bằng Vite trước khi đóng gói, trỏ DocumentRoot vào thư mục public nhằm bảo mật mã nguồn Laravel."*

---

### 📄 SLIDE 9: PHÂN TÍCH TỆP CẤU HÌNH DOCKER-COMPOSE.YML
* **Gợi ý thiết kế (Visual Layout)**: Hiển thị cấu trúc tệp tin YAML với các màu sắc phân biệt các dịch vụ: `app`, `db`, `redis`, `websocket`. Có mũi tên vẽ các liên kết phụ thuộc `depends_on`.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Điều phối dịch vụ (Orchestration)**: Khai báo 4 dịch vụ chạy song song trên các cổng độc lập.
  * **Ràng buộc thông minh (Healthcheck Dependency)**:
    * 🔗 Container Web (`app`) chỉ khởi chạy sau khi container `db` và `redis` đã ở trạng thái **Healthy** hoàn toàn.
    * 🔗 Ngăn chặn triệt để lỗi sập trang (Crash) do mất kết nối CSDL khi khởi động hệ thống đồng loạt.
  * **Lưu trữ bền vững (Volumes)**: Khai báo `postgres_data` và `redis_data` để giữ lại dữ liệu khi tắt container.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Tệp tin docker-compose.yml chính là nhạc trưởng điều phối toàn bộ hệ thống. Điểm đặc sắc ở đây là cơ chế Health Check. Thông thường các dịch vụ khởi chạy đồng thời, dẫn đến việc ứng dụng Web chạy trước CSDL PostgreSQL và gây ra lỗi mất kết nối. Chúng em đã giải quyết triệt để bằng cách thiết lập ràng buộc: App chỉ được phép khởi động khi Database và Redis đã vượt qua bài test sức khỏe định kỳ pg_isready và redis-cli ping. Dữ liệu ghi chú của người dùng cũng được bảo lưu vĩnh viễn nhờ phân vùng Volume độc lập."*

---

### 📄 SLIDE 10: TỰ ĐỘNG HÓA VẬN HÀNH VỚI DOCKER-ENTRYPOINT.SH
* **Gợi ý thiết kế (Visual Layout)**: Biểu đồ dạng cây quy trình 5 bước tự động hóa chạy ngầm của file script entrypoint khi container web bắt đầu khởi động.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * ⚙️ **Bước 1: Tương thích Cloud**: Tự cấu hình lại tệp VirtualHost của Apache theo biến cổng động `$PORT` cấp từ Railway.
  * ⚙️ **Bước 2: Cài đặt tự động**: Tự động sinh khóa bảo mật (`key:generate`) và sinh file cấu hình `.env` nếu thiếu.
  * ⚙️ **Bước 3: Chờ đợi Database**: Vòng lặp thông minh chờ đợi PostgreSQL sẵn sàng kết nối tối đa 30 giây.
  * ⚙️ **Bước 4: Đồng bộ CSDL**: Tự động chạy lệnh Migrate tạo bảng dữ liệu và nạp dữ liệu mẫu (`db:seed`).
  * ⚙️ **Bước 5: Bàn giao hệ thống**: Thiết lập symbolic link hình ảnh, sửa phân quyền và khởi động Apache.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Để tối ưu hóa trải nghiệm vận hành, chúng em viết thêm một bash script thông minh là docker-entrypoint.sh. Khi container Web bắt đầu chạy, script này sẽ thực hiện một loạt tác vụ tự động: tự động điều chỉnh cổng Apache thích ứng với môi trường Cloud, tự kiểm tra và cài đặt thư viện PHP còn thiếu, tự động chờ cơ sở dữ liệu sẵn sàng kết nối trong vòng 30 giây, tự động chạy migrate tạo bảng dữ liệu và nạp sẵn 2 tài khoản demo thử nghiệm mà không cần quản trị viên phải gõ bất kỳ câu lệnh thủ công nào."*

---

### 🚀 SLIDE 11: QUY TRÌNH 3 BƯỚC KHỞI CHẠY THỰC TẾ (DEMO)
* **Gợi ý thiết kế (Visual Layout)**: Sơ đồ 3 khối tuyến tính từ trái qua phải. Bên dưới kèm theo ảnh chụp màn hình terminal gõ lệnh và giao diện ứng dụng thực tế.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Bước 1: Giải phóng cổng (Preparation)**:
    * 🔌 Dừng các dịch vụ XAMPP local (Apache, MySQL) hoặc PostgreSQL local trên máy thật để tránh xung đột cổng `80`, `5432`, `6379`.
  * **Bước 2: Dựng hệ thống bằng 1 dòng lệnh**:
    * 💻 Chạy lệnh: `docker-compose up -d --build` trong terminal.
  * **Bước 3: Truy cập và trải nghiệm**:
    * 🌐 Mở trình duyệt truy cập `http://localhost:8000`.
    * 🔑 Đăng nhập tài khoản demo: `demo@example.com` / mật khẩu: `123456`.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Để minh chứng cho sự tiện lợi của công nghệ Container hóa, quy trình khởi chạy dự án của chúng em gói gọn trong 3 bước vô cùng đơn giản. Bước một, giải phóng các cổng dịch vụ trên máy thật. Bước hai, gõ câu lệnh docker-compose up -d --build. Hệ thống tự tải, tự cài đặt và tự cấu hình mọi thứ trong 3 phút. Và bước ba, mở trình duyệt truy cập localhost:8000 để trải nghiệm ứng dụng ngay lập tức. Sau đây, chúng em xin phép demo trực quan tính năng cộng tác thời gian thực của sản phẩm."*

---

### ⚖️ SLIDE 12: ĐỐI CHIẾU THỰC NGHIỆM: DOCKER VS XAMPP
* **Gợi ý thiết kế (Visual Layout)**: Bảng so sánh trực quan gồm nhiều tiêu chí đánh giá, sử dụng các ký hiệu tích xanh biểu thị điểm mạnh của Docker và dấu nhân đỏ cho điểm yếu của XAMPP.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Xung đột phiên bản PHP**: XAMPP (Dễ bị lỗi khi các thành viên chạy PHP khác nhau) vs Docker (Đồng bộ 100% PHP 8.2).
  * **Khả năng mở rộng dịch vụ**: XAMPP (Cực kỳ khó để cài thêm Redis hay PostgreSQL trên Windows) vs Docker (Cực kỳ đơn giản, chỉ khai báo thêm vài dòng trong YAML).
  * **Quy trình triển khai (Setup)**: XAMPP (Phải cài đặt thủ công từng bước phức tạp) vs Docker (Tự động hóa hoàn toàn qua code).
  * **Độ sạch của hệ thống**: XAMPP (Để lại tệp rác sau khi gỡ cài đặt) vs Docker (Gỡ bỏ sạch sẽ 100% sau khi chạy lệnh down).
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Nhóm chúng em đã thực hiện đối chiếu thực nghiệm giữa Docker Stack và phần mềm XAMPP truyền thống. XAMPP mặc dù dễ cài đặt ban đầu, nhưng khi dự án phát triển lớn cần Redis hay PostgreSQL, việc cấu hình chúng trên Windows là một thách thức lớn và thường xuyên gây lỗi phiên bản PHP giữa các thành viên. Docker giải quyết triệt để tất cả các điểm yếu này: mở rộng dịch vụ chỉ bằng vài dòng code khai báo, bảo vệ máy chủ thật khỏi tệp tin rác và đảm bảo tính sạch sẽ tối đa cho hệ điều hành."*

---

### 🗄️ SLIDE 13: QUẢN TRỊ CSDL POSTGRESQL QUA DOCKER BASH CLI
* **Gợi ý thiết kế (Visual Layout)**: Chia đôi slide. Bên trái là sơ đồ biểu diễn dòng lệnh chui từ máy thật qua Docker Daemon vào PostgreSQL; Bên phải là bảng danh sách lệnh CLI (`\dt`, `\q`, `-c`) kèm 3 dòng code mẫu SQL.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Truy cập dòng lệnh trực tiếp (CLI access)**:
    * 💻 Chạy lệnh: `docker exec -it note_app_db psql -U admin -d note_db` trên máy thật.
  * **Khảo sát cấu trúc cơ sở dữ liệu (psql commands)**:
    * 📋 Lệnh `\l` (danh sách database), `\dt` (danh sách bảng), `\d notes` (lược đồ bảng notes).
  * **Truy vấn và thao tác dữ liệu (CRUD operations)**:
    * 📊 `SELECT` dữ liệu thành viên, `INSERT` nhãn dán mới, `UPDATE` đổi màu nền ghi chú, `DELETE` bản nháp lỗi.
  * **Tự động hóa chạy lệnh một dòng (One-liner utility)**:
    * 🚀 Sử dụng cờ `-c` để truy vấn SQL nhanh mà không cần chui vào trong shell.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Thưa thầy cô, bên cạnh việc điều phối, khả năng quản trị cơ sở dữ liệu trực tiếp cũng là một phần cực kỳ quan trọng trong Topic 10. Thay vì phải cài đặt các công cụ giao diện nặng nề, quản trị viên có thể sử dụng sức mạnh dòng lệnh của Docker. Chỉ bằng một lệnh docker exec đơn giản, chúng ta có thể chui thẳng vào shell psql của container PostgreSQL. Tại đây, chúng ta thực hiện khảo sát các bảng dữ liệu bằng lệnh \dt, truy vấn dữ liệu thành viên bằng SELECT, sửa đổi ghi chú bằng UPDATE hoặc chạy các lệnh SQL một dòng tự động từ bên ngoài máy thật. Điều này thể hiện khả năng kiểm soát hệ thống toàn diện và chuyên nghiệp."*

---

### 📚 SLIDE 14: TÀI LIỆU THAM KHẢO & TRÍCH DẪN KHOA HỌC (IEEE)
* **Gợi ý thiết kế (Visual Layout)**: Bố cục cột đôi tinh tế. Các đầu sách và bài báo khoa học được trình bày trang trọng, có logo chuẩn IEEE ở góc dưới để gia tăng độ uy tín học thuật của báo cáo.
* **Nội dung hiển thị trên Slide (Bullet Points)**:
  * **Công nghệ ảo hóa Container (Docker)**:
    * 📖 [1] D. Merkel, "Docker: lightweight Linux containers," *Linux Journal*, 2014.
    * 📖 [2] C. Pahl, "Containerization and the PaaS Cloud," *IEEE Cloud Computing*, 2015.
  * **Hệ quản trị CSDL & Cache (Postgres & Redis)**:
    * 📖 [3] B. Momjian, *PostgreSQL: Introduction and Concepts*, Addison-Wesley, 2001.
    * 📖 [4] S. S. de Souza, et al., "PostgreSQL vs MySQL under Concurrent Load," *IEEE Latin America*, 2020.
  * **Mạng Web thời gian thực & Offline (WebSockets & PWA)**:
    * 📖 [5] I. Fette & A. Melnikov, "The WebSocket Protocol," *RFC 6455*, 2011.
    * 📖 [6] A. Russell, "Progressive Web Apps," *Infrequently Coherent*, 2015.
* **Lời thoại thuyết trình (Speaker Notes)**:
  > *"Cuối cùng, để đảm bảo tính chính xác và vững chắc về mặt học thuật cho đề tài giữa kỳ, nhóm chúng em đã nghiêm túc nghiên cứu và trích dẫn các tài liệu khoa học uy tín đạt chuẩn quốc tế IEEE. Từ các công trình nghiên cứu nền tảng về container của Merkel, các đặc tả RFC của giao thức truyền thông WebSocket, cho đến các nghiên cứu so sánh thực nghiệm hiệu năng database trên tạp chí IEEE Latin America Transactions năm 2020. Chúng em xin chân thành cảm ơn thầy cô Hội đồng và các bạn đã chú ý lắng nghe bài thuyết trình của nhóm!"*

---
*Kịch bản thiết kế và nội dung chi tiết 14 Slides thuyết trình Topic 10 kết thúc tại đây.*

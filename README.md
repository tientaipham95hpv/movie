# 🎬 Phim Hay iOS - App Xem Phim Tự Động Build IPA Unsigned qua GitHub Actions

Ứng dụng xem phim dành cho iOS (iPhone/iPad) được phát triển bằng **SwiftUI**, tích hợp dữ liệu từ 2 nguồn API: **VSPHIM** (`nguon.vsphim.com`) và **AVDB API** (`avdbapi.com`).

---

## 🌟 Tính Năng Nổi Bật

1. **Tích hợp Dual-Source (2 API)**:
   - **VSPHIM**: Phim bộ, phim lẻ, Vietsub chất lượng cao.
   - **AVDB API**: Kho phim AVDB phong phú.
   - Chuyển đổi nhanh giữa các nguồn hoặc xem danh sách tổng hợp.
2. **Trình Phát Video Thông Minh (`WKWebView Player`)**:
   - Tự động phát inline và chuyển đổi Fullscreen Native iOS Video Player.
   - Inject script **chặn quảng cáo popup đè** (Popup Blocker / AdBlocker).
   - Hỗ trợ Picture-in-Picture (PiP) và xoay ngang màn hình (Auto Rotate Landscape).
3. **Tìm Kiếm & Bộ Lọc**:
   - Tìm kiếm nhanh từ khóa qua 2 hệ thống API.
   - Phân trang tự động (Infinite Scroll & Pull-to-refresh).
4. **Build Auto IPA Unsigned qua GitHub Actions**:
   - Không cần Mac, không cần Xcode trên máy tính cá nhân.
   - Không cần mua tài khoản Apple Developer ($99/năm).
   - Tự động đóng gói file `.ipa` khi push code lên GitHub.

---

## 🛠 Hướng Dẫn Sử Dụng & Build File IPA

### Bước 1: Đẩy Code Lên GitHub Repository
1. Tạo 1 Repository mới trên GitHub (ví dụ: `movie-app-ios`).
2. Mở Terminal tại thư mục dự án và chạy các lệnh sau:
   ```bash
   git init
   git add .
   git commit -m "Initial commit - MovieApp SwiftUI"
   git branch -M main
   git remote add origin https://github.com/USERNAME/movie-app-ios.git
   git push -u origin main
   ```

### Bước 2: Tải File `.ipa` Từ GitHub Actions
1. Vào tab **Actions** trên GitHub Repository của bạn.
2. Chọn workflow **Build Unsigned iOS IPA** và đợi khoảng 2 - 3 phút để hệ thống build xong.
3. Khi dấu tick xanh xuất hiện, cuộn xuống phần **Artifacts** và bấm tải file `MovieApp-Unsigned-IPA.zip`.
4. Giải nén file `.zip` sẽ thu được file `MovieApp_Unsigned.ipa`.

### Bước 3: Cài Đặt File IPA Vào Thiết Bị iOS (Sideloading)
Bạn có thể cài đặt file `.ipa` unsigned vào iPhone/iPad bằng một trong các phương thức sau:
* **TrollStore** *(Khuyên dùng - Dành cho iOS hỗ trợ TrollStore)*: Mở file `.ipa` trực tiếp bằng TrollStore để cài đặt vĩnh viễn không bao giờ hết hạn.
* **Sideloadly / AltStore / SideStore**: Cài qua máy tính bằng tài khoản Apple ID Free (gia hạn 7 ngày 1 lần).
* **Feather / Scarlet / Esign**: Dùng Cert cá nhân hoặc cert doanh nghiệp để ký và cài đặt trực tiếp trên điện thoại.

---

## 💡 Gợi Ý Các Tính Năng Nâng Cao (Phiên Bản Tiếp Theo)

Sau khi app chạy ổn định, các tính năng đáng giá có thể nâng cấp thêm bao gồm:

1. **HLS Stream Extractor (`.m3u8` Direct Player)**:
   - Dùng Regex / Parser để bóc tách luồng video `.m3u8` trực tiếp từ `link_embed` để phát bằng **AVPlayer / KSPlayer** thay vì `WKWebView`. Giúp xem mượt hơn, tiết kiệm pin, chỉnh tốc độ phát 1.5x/2x và tải phim xem offline.
2. **Tính Năng Lịch Sử Xem (Continue Watching)**:
   - Lưu thời gian đang xem dở (ví dụ `01:23:45`) vào `UserDefaults` / `CoreData`. Cho phép người dùng bấm "Xem tiếp" ngay tại Trang chủ.
3. **Danh Sách Phát & Download Phim Offline**:
   - Tải tập phim về bộ nhớ máy để xem khi không có kết nối mạng (dành cho các luồng HLS `.m3u8`).
4. **Tích Hợp Cast (AirPlay & Chromecast)**:
   - Truyền video trực tiếp từ iPhone lên TV (Apple TV, Smart TV Samsung/LG, Chromecast).
5. **Khóa Ứng Dụng (Face ID / Touch ID / Passcode)**:
   - Bảo mật riêng tư khi mở app bằng Face ID hoặc Mã PIN.

# Lịch sử phiên bản

## 2.0.0 - 2026-10-19

Build: `2.0.0+6` · Git tag: `v2.0.0`

### Mục tiêu

Thu gọn app quanh việc theo dõi thay đổi của da và duy trì chăm sóc hằng ngày. Đây là bản cập nhật lớn về giao diện và tổ chức chức năng; không phải bản nâng cấp mô hình AI.

### Điều hướng và chức năng

- Thay 5 tab bằng 4 mục: **Hôm nay → Theo dõi da → Chăm sóc → Cá nhân**.
- Hôm nay hiển thị kết quả gần nhất và tiến độ routine sáng/tối, có lối mở Chăm sóc để thực hiện các bước.
- Theo dõi da tập trung biểu đồ số nốt từ kết quả thật và lịch sử đã lưu; hỗ trợ tải lại và thử lại khi lỗi.
- Chăm sóc quản lý checklist, chỉnh các bước, mở sản phẩm của tôi và khám phá sản phẩm.
- Cá nhân tập trung hồ sơ da, tài khoản và cài đặt; bỏ lối vào tủ đồ/lịch sử trùng lặp. Giữ quyền truy cập quản trị cho admin.
- Routine lưu trên thiết bị theo tài khoản, dùng chung trạng thái giữa các mục và đặt lại tiến độ theo ngày.

### Giao diện và nền tảng

- Đồng bộ theme xanh–tím, nền, thẻ nội dung và giao diện sáng/tối trên các màn hình.
- Cập nhật nhận diện màn đăng nhập với logo Google/Facebook và logo app.
- Đơn giản hóa splash Android/iOS/web; bổ sung cấu hình CocoaPods và nâng iOS deployment target lên 15.0.
- Cập nhật giao diện bản demo; demo vẫn là môi trường riêng, không phản ánh toàn bộ phạm vi chức năng đang bật trong app thật.
- Cải thiện xử lý lỗi lưu/xóa lịch sử cục bộ và dọn dữ liệu routine khi xóa tài khoản.

### Tạm ẩn và giới hạn

- Tạm ẩn Cộng đồng, thông báo cộng đồng, MeowSkin Plus cùng mục giao dịch Premium và nút báo cáo chưa hoạt động khỏi luồng chính. Mã nguồn và dữ liệu được giữ lại.
- **Quét AI vẫn đang bảo trì**; không bật lại camera hoặc phân tích ảnh trong bản này. Người dùng vẫn xem được kết quả đã lưu.
- Biểu đồ thể hiện số nốt được phát hiện, không phải điểm sức khỏe da hoặc chẩn đoán.
- Không thay đổi mô hình AI, không xóa dữ liệu Firebase và không triển khai Firebase rules/hosting trong lần cập nhật GitHub này.
- Chưa xác nhận bản phát hành trên thiết bị thật hoặc xây dựng APK/IPA mới. Các APK cũ trong kho không đại diện cho bản 2.0.

### Xác minh

- `flutter analyze`: không có lỗi hoặc cảnh báo.
- `flutter test`: 49/49 test thành công.
- Kiểm thử điều hướng 4 mục ở cả hai ngôn ngữ và theme; biểu đồ dữ liệu thật; lưu routine theo tài khoản; đồng bộ tiến độ rút gọn; đăng nhập và xử lý lịch sử.

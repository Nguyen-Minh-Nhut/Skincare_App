# Lịch sử phiên bản

## 2.0.1 - 2026-10-19

Build: `2.0.1+7` · Git tag: `v2.0.1`

- Thêm gói YOLO mobile nhúng 157 buffer trọng số để runtime di động không báo thiếu tensor. Giữ nguyên byte trọng số, kiểm tra đầu ra cùng input sai khác bằng 0; bản model gốc vẫn giữ cho nghiên cứu.
- Thêm kiểm tra ảnh một khuôn mặt trên mobile bằng ML Kit/Vision: phát hiện không có mặt, nhiều mặt, góc nghiêng lớn và mặt quá xa; chặn ảnh quá tối/sáng bằng heuristic.
- Cho xoay ảnh và chọn lại khi không đạt. Ghi rõ hạn chế mụn đầu đen, nguy cơ bỏ sót/nhận nhầm; không thay ngưỡng acne model.
- Worker nền sở hữu hai interpreter, trả lỗi về UI và có thời hạn chờ để tránh treo khi model thất bại; lưu cả khung nhận diện để xem lại trong lịch sử. Lịch sử cũ vẫn đọc được; ẩn các dòng routine/hoạt chất trống.
- Sửa Google Sign-In: không giới hạn 10 giây ở cửa sổ chọn tài khoản/xác minh, kiểm tra ID token và hiển thị mã lỗi cụ thể. Chưa xác nhận OAuth Google trên điện thoại thật.
- Thêm kiểm thử đăng nhập qua Firebase emulator và kiểm tra ảnh–quét–lưu trên Android, cùng bài thử mở tiến trình mới để đọc lại lịch sử. Cấu hình HTTP localhost chỉ áp dụng bản debug.
- Sửa lỗi Run main.dart trên Chrome (`dart:ffi is not available`): conditional export màn quét native/web, web dẫn tới bộ kiểm thử cục bộ.

- Sửa đầu vào YOLO NCHW `[1,3,640,640]`: dùng trực tiếp TFLite cho cả hai model thay vì plugin Android giả định NHWC; giải mã output chuẩn hóa và hoàn tác letterbox.
- Mở luồng quét thử nghiệm trên Android/iOS: chọn/chụp ảnh, phân tích, xem khung, lưu và xem lịch sử. Thêm quyền camera/thư viện cho iOS.
- Thay server trả cố định 3 nốt bằng trang kiểm thử AI cục bộ chạy hai model TFLite thật trên Mac. Có ảnh mẫu/đối chứng, lỗi ảnh, kết quả JSON và lịch sử trong phiên.
- Chuẩn hóa chiều ảnh trước khi nhận diện/lưu; không hiển thị lỗi decode/classifier như kết quả 0 nốt. Bỏ diễn giải mức độ bệnh và lời khuyên thuốc dựa trên số vùng.
- Trang thử browser chưa kiểm tra khuôn mặt/ánh sáng tự động. Chưa xác nhận trên điện thoại thật.

Xác minh: 60 bài Flutter và 5 bài Python thành công; luồng Android giả lập và lưu trữ qua tiến trình mới đạt; web release và iOS simulator arm64 build thành công. Chi tiết ở [báo cáo kiểm thử](deliverables/v2.0.1-validation.md).

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

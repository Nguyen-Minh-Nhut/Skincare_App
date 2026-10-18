# Hoàn tất cấu hình quên mật khẩu

Callback / email action URL cần dùng cho project `myapp-7f561`:

```text
https://myapp-7f561-auth.web.app/reset-password
```

## Cấu hình Firebase Console

1. Mở đúng project [myapp-7f561](https://console.firebase.google.com/project/myapp-7f561/authentication/emails).
2. Trong Authentication → Settings → Authorized domains, kiểm tra có `myapp-7f561-auth.web.app`. Chỉ nhập hostname, không nhập `https://` hoặc đường dẫn. Lần cấu hình ngày 15/09 đã ghi nhận miền này được thêm thành công; cần kiểm tra lại trạng thái Console hiện tại.
3. Vào Authentication → Templates → Password reset → chỉnh sửa → Customize action URL. Dán chính xác URL trên và lưu. Giữ liên kết hành động `%LINK%` trong nội dung mẫu thư.
4. Mở lại cấu hình để xác nhận URL đã được lưu. Không tự thêm `mode`, `oobCode`, `apiKey` hoặc email vào callback: Firebase sẽ gắn tham số cho từng thư.

Đây là URL xử lý email action, không phải OAuth redirect URI `/__/auth/handler`. `ActionCodeSettings.url` là continue URL để truyền trạng thái/quay lại ứng dụng; đặt nó thành URL trang reset không thay thế cấu hình callback trong Templates. App hiện gọi `sendPasswordResetEmail(email: email)`, còn form trên web gọi `sendOobCode` với `PASSWORD_RESET`: cả hai dùng callback của project nên không cần sửa mã gửi thư hoặc build lại app để đổi callback.

Thay đổi action URL cũng áp dụng cho các email action khác. Trang hiện có nút chuyển tiếp những action xác minh/khôi phục được hỗ trợ về handler Firebase gốc.

## Thử lại bằng thư mới

1. Dùng email của một tài khoản thử nghiệm đã tồn tại trong Authentication → Users, có thể đăng nhập bằng mật khẩu. Nếu muốn dùng địa chỉ email mới, hãy đăng ký tài khoản thử nghiệm đó trước.
2. Trong app, chọn Quên mật khẩu, nhập email và gửi. Hoặc mở URL trên để yêu cầu thư. Giao diện chờ 60 giây trước khi cho gửi lại; thông báo gửi thành công không khẳng định email có tài khoản, nhằm tránh lộ danh sách người dùng.
3. Mở **thư vừa được gửi sau khi lưu callback**, kiểm tra cả Spam. Link đích phải có hostname `myapp-7f561-auth.web.app`, đường dẫn `/reset-password`, và tham số `mode=resetPassword`, `oobCode`, `apiKey`. Không chia sẻ link thật vì mã dùng để thay mật khẩu. Trang chủ động xóa query khỏi thanh địa chỉ ngay khi tải, nên kiểm tra link trong email trước khi bấm.
4. Trang kiểm tra mã rồi hiện form mật khẩu và xác nhận mật khẩu. Nhập mật khẩu đáp ứng chính sách Firebase, lưu và chờ thông báo thành công.
5. Quay lại app, đăng nhập bằng mật khẩu mới. Đăng xuất trước nếu đang có phiên đăng nhập. Kiểm tra mật khẩu cũ không còn đăng nhập được và mở lại link đã dùng phải yêu cầu link mới.

Mở URL không có mã sẽ hiện form xin thư mới, không phải form đổi mật khẩu. Reload trang sau khi query đã bị xóa cũng hiện form xin thư; để tiếp tục mã chưa dùng, mở lại link gốc trong email. Thư cũ vẫn giữ URL cũ; đổi callback không sửa lại thư đã gửi và không khôi phục mã hết hạn/đã dùng.

## Nếu vẫn không lưu được callback

Ngày 15/09/2026 đã ghi nhận lỗi `EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED` khi lưu trên Console và khi cập nhật cấu hình qua API. Đây là trạng thái lịch sử, chưa kiểm tra lại cấu hình quản trị trong đợt rà soát này. Nếu lỗi lặp lại, callback chưa được lưu; thêm Authorized domains hoặc deploy lại trang không chứng minh callback đã đổi. Dùng [nội dung gửi Firebase Support](firebase-auth-support.md) để yêu cầu kiểm tra project. Chưa có căn cứ để khẳng định đổi gói thanh toán hoặc sửa mã phía app sẽ giải quyết lỗi này.

## Kết quả kiểm tra ngày 19/09/2026 (giờ Việt Nam)

- URL trên trả HTTP 200. HTML, `reset-password.js`, `auth-api.js`, CSS và logo trên Hosting khớp từng byte với mã nguồn local. Không cần deploy lại cho cập nhật tài liệu này.
- Hosting dùng site riêng `myapp-7f561-auth`; API key web khớp cấu hình Firebase web của project `myapp-7f561`.
- Rà soát đường đi: hộp thoại app → gửi email Firebase → đọc `mode`/`oobCode` → xác minh mã → nhập/xác nhận mật khẩu → gửi mật khẩu mới → quay về app đăng nhập. Có xử lý timeout, lỗi mạng, mã hết hạn/đã dùng và yêu cầu gửi lại.
- 11 test Flutter của dialog/auth screen/auth wrapper đều qua.
- 7 test web đều qua khi chạy Auth emulator, bao gồm đổi mật khẩu bằng mã hợp lệ, đăng nhập bằng mật khẩu mới, từ chối mật khẩu cũ và từ chối dùng lại mã.
- Chưa gửi email production hoặc thử mã thật; việc lưu callback, nhận email và đăng nhập trên thiết bị thật cần hoàn tất theo các bước trên. Test emulator không xác nhận cấu hình Templates, chính sách mật khẩu hay khả năng gửi thư production.

Tham khảo chính thức: [Custom email action handlers](https://firebase.google.com/docs/auth/custom-email-handler), [Passing state in email actions](https://firebase.google.com/docs/auth/web/passing-state-in-email-actions).

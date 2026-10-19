# Skincare App 2.0

Ứng dụng Flutter hỗ trợ theo dõi tình trạng da, phát hiện vùng nghi ngờ mụn trên ảnh và lưu lịch sử phân tích. Kết quả chỉ mang tính tham khảo, không thay thế chẩn đoán hoặc tư vấn của bác sĩ da liễu.

**Phiên bản:** `2.0.1+7` · [Chi tiết thay đổi bản 2.0.1](CHANGELOG.md#201---2026-10-19).

## Chức năng chính

- Đăng ký, đăng nhập và quản lý hồ sơ với Firebase.
- Chụp/chọn ảnh, quét AI ở chế độ thử nghiệm và lưu lịch sử trên thiết bị.
- Phát hiện vùng nghi ngờ bằng YOLO11m chạy cục bộ.
- Kết hợp YOLO11m và MobileNetV2 để giảm nhận diện thiếu, trùng và dương tính giả.
- Loại bounding box trùng bằng Non-Maximum Suppression.
- Hiển thị, lưu và xem lại lịch sử phân tích.
- Giao diện tiếng Việt/tiếng Anh, chế độ sáng/tối.
- Mã nguồn trợ lý Gemini được giữ lại; không nằm trong luồng chính của bản 2.0.

## Giao diện

- Điều hướng chính gồm Hôm nay, Theo dõi da, Chăm sóc và Cá nhân.
- Hôm nay hiển thị kết quả gần nhất và tiến độ sáng/tối; mở Chăm sóc để đánh dấu hoặc chỉnh routine.
- Theo dõi da tập trung biểu đồ số nốt và lịch sử đã lưu. Quét AI có lối vào thử nghiệm trên Android/iOS.
- Chăm sóc là nơi quản lý routine và sản phẩm. Cá nhân chứa hồ sơ da, tài khoản và cài đặt.
- Cộng đồng, thông báo cộng đồng và MeowSkin Plus tạm ẩn khỏi luồng chính; mã nguồn và dữ liệu được giữ lại.
- Checklist lưu cục bộ theo tài khoản, dùng chung trạng thái giữa các mục.

## Chạy app trên Chrome từ Android Studio

Chọn cấu hình `main.dart` và thiết bị `Chrome (web)`, rồi Run. Màn quét dùng conditional export: Android/iOS tải TFLite native; bản web hiển thị lối mở trang thử AI cục bộ và không nhập `dart:ffi`.

Có thể chạy bằng terminal:

```sh
flutter run -d chrome -t lib/main.dart
```

Trên web, Theo dõi da → Mở quét thử nghiệm → Mở trang thử AI cục bộ. Khởi động bộ chạy qua `Start AI Browser.command` nếu cần. Bản `preview_main.dart` chỉ là demo giao diện riêng.

## Kiểm thử AI bằng trình duyệt

Chạy hai model thật trên Mac, chọn ảnh và xem khung kết quả trong trình duyệt; không cần Android. Xem [hướng dẫn bộ chạy cục bộ](tools/scan_browser/README.md). Đây là trang kiểm thử riêng, lịch sử chỉ giữ trong phiên và không đồng bộ với app. Chưa xác minh độ chính xác hay hiệu năng trên điện thoại thật.

## Pipeline AI

1. Đọc và chuẩn hóa chiều ảnh trước khi quét/lưu. YOLO nhận tensor NCHW `[1,3,640,640]`; pipeline dùng hai model TFLite thật.
2. Letterbox nền 114, RGB /255; giải mã output `[1,5,8400]` với tọa độ xywh chuẩn hóa, hoàn tác padding và NMS detector 0.70.
3. Lọc ngưỡng confidence `0.08`, kích thước vùng và ellipse trung tâm. Ellipse không phải bộ phát hiện khuôn mặt.
4. Giữ trực tiếp vùng nhỏ có confidence từ `0.15`; các vùng còn lại mở rộng crop 2x và qua MobileNetV2 NCHW `[1,3,224,224]` với ImageNet normalization.
5. Lọc xác suất `normal/acne`, rồi NMS IoU `0.30` và containment `0.70` để loại khung trùng.
6. Hiển thị số vùng nghi ngờ. Không suy ra mức độ bệnh hoặc chọn thuốc từ số vùng. Lỗi model/ảnh không được coi là kết quả 0 nốt.

Bộ chạy trình duyệt và app dùng cùng dạng tensor và quy tắc lọc, nhưng runtime/resize khác nhau; cần xác minh lại trên thiết bị thật.

## Yêu cầu

- Flutter tương thích với Dart SDK `^3.11.5`.
- Android SDK và một emulator hoặc thiết bị Android.
- Cấu hình Firebase phù hợp cho nền tảng cần chạy.
- Gemini API key nếu sử dụng màn hình Meow AI.

## Chạy dự án

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Không đưa khóa Gemini vào mã nguồn hoặc commit khóa lên Git. Với bản production, nên gọi Gemini thông qua API server để tránh khóa bị trích xuất từ ứng dụng mobile.

## Kiểm tra

```bash
flutter analyze
flutter test
```

Benchmark pipeline trên Android Emulator ở chế độ profile:

```bash
flutter run --profile -d emulator-5554 -t lib/benchmark_main.dart
```

## Mô hình và tài sản

- `assets/models/acne_detector.tflite`: bản YOLO11m gốc cho bộ chạy nghiên cứu.
- `assets/models/acne_detector_mobile.tflite`: bản đóng gói trọng số nhúng cho runtime mobile; giữ nguyên trọng số/đồ thị, kiểm tra đầu ra bằng nhau. Provenance ở `assets/models/mobile-packaging.json`; tái tạo bằng `.venv-ai/bin/python -m tools.scan_browser.pack_mobile_model`.
- `assets/models/model_phan_loai_mun.tflite`: MobileNetV2 phân loại `normal/acne`.
- `deliverables/sequence_diagram_ai.svg`: biểu đồ tuần tự của pipeline triển khai.

## Lưu ý an toàn

Ứng dụng là nguyên mẫu phục vụ học tập và nghiên cứu. Độ chính xác phụ thuộc dữ liệu huấn luyện, chất lượng ảnh, ánh sáng, thiết bị và đặc điểm da. Không sử dụng kết quả để tự chẩn đoán hoặc thay đổi phác đồ điều trị.

## Kiểm thử quyền Firestore

Bộ test chạy với project demo cục bộ, không dùng dữ liệu Firebase thật:

```bash
npm --prefix tests/firestore ci
firebase emulators:exec --config firebase.test.json --only firestore --project demo-skincare-rules 'npm --prefix tests/firestore test'
```

Cần Node.js tương thích các thư viện trong `tests/firestore/package-lock.json`, Firebase CLI và Java để chạy emulator.

### Triển khai thay đổi tương tác

- App mới dùng transaction cho lượt thích và bình luận. Rules mới chỉ cho phép sửa tương tác của chính người đăng nhập; bộ đếm bình luận phải đi cùng thao tác thêm/xóa bình luận trong một commit.
- Thông báo phải gắn với một tương tác hợp lệ trong cùng commit. Mỗi người chỉ tạo thông báo lượt thích đầu tiên cho một bài, được đánh dấu bằng `likeReceipts`.
- Cần phát hành app và rules theo cùng kế hoạch: app cũ ghi bình luận/bộ đếm riêng sẽ bị rules mới từ chối; rules cũ chưa hỗ trợ `likeReceipts` và `lastCommentId` của app mới. Kiểm tra trên project staging trước khi chuyển người dùng sang bản mới.
- Bộ test emulator không triển khai rules. Các APK có sẵn trong thư mục dự án chưa chứa thay đổi này.

### Xóa tài khoản

Xác thực lại bằng mật khẩu hoặc Google, dọn `wardrobe`, `notifications`, hồ sơ và tên đăng nhập; xóa lịch sử ảnh/chat của người dùng trên thiết bị hiện tại rồi mới xóa Firebase Auth. Nếu lỗi giữa chừng, giao diện báo chưa hoàn tất để người dùng thử lại. Quá trình này gồm nhiều bước nên một phần dữ liệu có thể đã bị xóa trước khi lỗi xảy ra.

Bài viết/bình luận cộng đồng và lịch sử cục bộ trên các thiết bị khác không được xóa bởi luồng này; hộp thoại xác nhận nêu rõ phạm vi. Cần kiểm tra xác thực Google và xóa tài khoản bằng tài khoản thử nghiệm trên thiết bị thật trước khi phát hành.

## Trang web đặt lại mật khẩu

Hướng dẫn hoàn tất Firebase Console và thử lại bằng thư mới: [Cấu hình quên mật khẩu](deliverables/password-reset-setup.md). Rà soát ngày 19/09/2026: trang live và các asset khớp mã nguồn; 11 test Flutter và 7 test web/Auth emulator đều qua. Chưa xác nhận lại callback trong cấu hình quản trị production.

- Mã nguồn: `auth_web/` (HTML/CSS/JavaScript, logo dùng lại từ app).
- Hosting riêng: `myapp-7f561-auth`, cùng project `myapp-7f561`; website ở Hosting mặc định không bị thay thế.
- URL: `https://myapp-7f561-auth.web.app/reset-password`.
- Trang xác minh `oobCode` trước khi cho đặt mật khẩu, xử lý link hết hạn/đã dùng, lỗi mạng và timeout. Có form yêu cầu link mới và giới hạn gửi lại 60 giây.
- Firebase Auth REST được gọi trực tiếp, không tải SDK/CDN bên ngoài. API key phía web chỉ nhận diện project; không có thông tin đăng nhập quản trị trong trang.
- Các email action khác được chuyển tiếp bằng nút tới trình xử lý Firebase gốc để giữ luồng xác minh email/khôi phục tài khoản.

Kiểm thử với Firebase Auth emulator, không gửi thư thật:

```bash
firebase emulators:exec --config firebase.auth-test.json --only auth --project demo-skincare-auth 'node --test auth_web/tests/*.test.js'
```

Triển khai riêng trang này:

```bash
firebase deploy --only hosting --config firebase.auth-hosting.json --project myapp-7f561
```

Trạng thái cấu hình (15/09/2026): trang đã triển khai và miền `myapp-7f561-auth.web.app` đã được thêm vào Authorized domains. Firebase vẫn từ chối cập nhật callback bằng lỗi `EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED`; email hiện vẫn dùng trang mặc định. Cần lưu thành công URL trên tại Firebase Authentication → Templates → Customize action URL để hoàn tất kết nối. Sau khi đổi cấu hình, yêu cầu một email mới từ app; email đã gửi trước đó vẫn chứa URL cũ. Link hết hạn/đã dùng không thể khôi phục bằng cách thay giao diện.

## Bản 2.0.1: kiểm tra đầu vào và lịch sử quét

- Mobile kiểm tra một khuôn mặt, độ nghiêng/khoảng cách và ánh sáng quá tối/sáng trước khi quét. Android dùng ML Kit face-detection 16.1.7 được đóng gói sẵn; iOS dùng Vision. Không tải ảnh lên server.
- Chuẩn hóa EXIF, cho xoay ảnh 90°. Ảnh ghép/nhiều mặt, không thấy mặt, mặt quá xa/nghiêng và ảnh cận da quá sát sẽ được yêu cầu chọn lại. Các ngưỡng là heuristic chụp ảnh, chưa phải đánh giá chất lượng được xác thực.
- Worker nền tự sở hữu hai interpreter, trả lỗi và có thời hạn chờ; màn hình hiển thị kiểm tra ảnh, phân tích, lưu và thông báo lỗi/thử lại. Lưu cả kích thước ảnh và tọa độ khung; lịch sử cũ vẫn đọc được. Chưa tự sửa ngưỡng nhận diện mụn.
- Mụn đầu đen còn hạn chế; có thể bỏ sót và khoanh nhầm watermark. Trang nghiên cứu AI trên trình duyệt vẫn là bộ chạy riêng và chưa có chốt khuôn mặt mobile.

Kiểm thử Android với Auth/Firestore emulator cục bộ (không deploy):

```sh
firebase emulators:start --config firebase.scan-test.json --only auth,firestore --project myapp-7f561
adb reverse tcp:9098 tcp:9098
adb reverse tcp:8085 tcp:8085
flutter drive --driver test_driver/scan_driver.dart --target integration_test/scan_flow_test.dart -d emulator-5554 --keep-app-running
flutter drive --driver test_driver/scan_driver.dart --target integration_test/scan_reopen_test.dart -d emulator-5554 --keep-app-running
```

Bài thử đăng nhập email tài khoản giả trong Auth emulator, mở quét, chọn fixture qua bộ chọn ảnh thay thế, chạy kiểm tra khuôn mặt và TFLite thật, lưu và mở lịch sử. Bài thứ hai chạy tiến trình mới để kiểm tra ảnh/kết quả còn trên đĩa. Không thay thế kiểm thử camera hoặc Google Sign-In trên điện thoại thật.

Dùng `flutter drive --keep-app-running` cho bài kiểm tra mở lại: `flutter test` sẽ gỡ app ở teardown và xóa dữ liệu, nên không phù hợp kiểm tra lưu trữ xuyên tiến trình giữa hai lần chạy.

Sau integration test, dùng `flutter build apk --release` (có bước pub/plugin generation), tránh dùng `--no-pub` với file đăng ký plugin còn từ chế độ test.

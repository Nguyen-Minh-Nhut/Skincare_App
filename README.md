# Skincare App

Ứng dụng Flutter hỗ trợ theo dõi tình trạng da, phát hiện vùng nghi ngờ mụn trên ảnh và lưu lịch sử phân tích. Kết quả chỉ mang tính tham khảo, không thay thế chẩn đoán hoặc tư vấn của bác sĩ da liễu.

## Chức năng chính

- Đăng ký, đăng nhập và quản lý hồ sơ với Firebase.
- Chụp ảnh hoặc chọn ảnh từ thiết bị.
- Phát hiện vùng nghi ngờ bằng YOLO11m chạy cục bộ.
- Kết hợp YOLO11m và MobileNetV2 để giảm nhận diện thiếu, trùng và dương tính giả.
- Loại bounding box trùng bằng Non-Maximum Suppression.
- Hiển thị, lưu và xem lại lịch sử phân tích.
- Giao diện tiếng Việt/tiếng Anh, chế độ sáng/tối.
- Trợ lý tư vấn chăm sóc da bằng Gemini khi được cấu hình khóa API.

## Pipeline AI

1. YOLO11m nhận ảnh với ngưỡng confidence ban đầu `0.08`.
2. Detection có confidence từ `0.15` trở lên được giữ trực tiếp.
3. YOLO11m đề xuất các vùng nghi ngờ trong vùng mặt hợp lệ.
4. Vùng nhỏ có confidence từ `0.15` được giữ trực tiếp.
5. Vùng yếu hoặc vùng lớn được mở rộng lấy ngữ cảnh da, đổi về `224 × 224` và đưa qua MobileNetV2.
6. Kết quả cuối được lọc bằng NMS để loại khung trùng.
5. NMS với ngưỡng IoU `0.30` loại các bounding box trùng lặp.

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

- `assets/models/acne_detector.tflite`: mô hình YOLO11m phát hiện vùng nghi ngờ.
- `assets/models/model_phan_loai_mun.tflite`: MobileNetV2 phân loại `normal/acne`.
- `deliverables/sequence_diagram_ai.svg`: biểu đồ tuần tự của pipeline triển khai.

## Lưu ý an toàn

Ứng dụng là nguyên mẫu phục vụ học tập và nghiên cứu. Độ chính xác phụ thuộc dữ liệu huấn luyện, chất lượng ảnh, ánh sáng, thiết bị và đặc điểm da. Không sử dụng kết quả để tự chẩn đoán hoặc thay đổi phác đồ điều trị.

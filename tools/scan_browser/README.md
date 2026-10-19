# Thử quét AI trên trình duyệt

Trang thử cục bộ, dùng hai model thật trong `assets/models/`. Không cần Android, Firebase hoặc khóa API; không trả kết quả giả lập. Trình duyệt gửi ảnh tới server trên cùng Mac qua loopback, Python chạy TFLite trên CPU. Không mở server ra mạng LAN/Internet.

## Mở lại sau khi đóng phiên chat

Trên Mac đã cài runtime, nhấp đúp `Start AI Browser.command` ở thư mục dự án. Script khởi động server độc lập, chờ hai model sẵn sàng rồi mở trình duyệt. Có thể đóng cửa sổ launcher sau khi khởi động. Nếu Mac khởi động lại hoặc server dừng, chạy lại file này.

Lệnh tương đương: `.venv-ai/bin/python tools/scan_browser/start.py`. Log ở `.scan-browser/server.log`, PID ở `.scan-browser/server.pid`; các file này không đưa lên Git.

## Khởi động

Cần Python 3.12 trên Mac Apple Silicon (hoặc Python tương thích wheel TensorFlow 2.20 trên hệ điều hành của bạn):

```sh
python3 -m venv .venv-ai
.venv-ai/bin/python -m pip install -r tools/scan_browser/requirements.txt
.venv-ai/bin/python server.py
```

Mở <http://127.0.0.1:8765>. Dừng bằng Ctrl+C. Có thể đổi cổng qua `--port 8766`.

## Cách thử

1. Chọn JPEG/PNG/WebP dưới 12 MB, ít nhất 224 pixel mỗi chiều, tối đa 20 megapixel. Có ảnh mẫu và ảnh đối chứng từ repo.
2. Bấm **Phân tích ảnh**, kiểm tra vị trí khung so với ảnh và số vùng nghi ngờ.
3. Thử ảnh có mụn, da ít/không mụn, nền cảnh vật, thiếu sáng và file hỏng. Số vùng bằng 0 không xác nhận da khỏe.
4. Lưu trong phiên để xem lại hoặc tải JSON có tọa độ và thời gian xử lý. Phiên giữ tối đa 10 kết quả trong bộ nhớ tab, mất khi tải lại/đóng tab. Không ghi ảnh lên đĩa hoặc Firebase.

## Phạm vi

- Chạy trực tiếp hai model NCHW: YOLO `[1,3,640,640] → [1,5,8400]`, classifier `[1,3,224,224] → [1,2]`. Cả Dart và Python dùng cùng hợp đồng tensor; letterbox 114, ngưỡng detector 0.08, giữ trực tiếp vùng nhỏ đạt 0.15, crop mở rộng 2x, ImageNet normalization NCHW, lọc xác suất và NMS như logic app.
- Runtime CPU và tiền xử lý PIL khác bộ xử lý ảnh Dart trên mobile. Đây là bộ chạy tham chiếu, không đảm bảo kết quả/tốc độ giống Android hoặc iOS.
- Chưa có bộ phát hiện khuôn mặt hay kiểm tra ánh sáng tự động; vùng ellipse trung tâm chỉ là heuristic. Kết quả không phải chẩn đoán; không phân loại mức độ bệnh hay đề xuất thuốc từ số vùng.
- Đây là trang kiểm thử AI riêng, không phải toàn bộ Flutter app chạy trên web. Lịch sử phiên không đồng bộ với lịch sử trên điện thoại.
- `server.py` cũ trả cố định 3 nốt đã được thay bằng suy luận thật. API mới nhận **bytes ảnh** tại `POST /analyze_skin`, không nhận JSON base64 cũ.

## Kiểm tra

```sh
.venv-ai/bin/python -m unittest tools.scan_browser.test_inference
```

## Kết quả kiểm tra trên Mac (19/10/2026)

- 56 test Flutter, 5 test Python đều qua; `flutter analyze` không có lỗi/cảnh báo.
- API và trình duyệt chạy thật: ảnh mẫu giữ 2 vùng, ảnh đối chứng giữ 0 vùng. Thời gian CPU tham khảo khoảng 130–230 ms/lượt trên máy phát triển, không đại diện tốc độ điện thoại.
- Đã kiểm tra lưu/mở lại kết quả trong phiên, từ chối file hỏng (HTTP 400) và Origin ngoài localhost (HTTP 403).
- Ảnh mẫu còn nhiều vùng nhìn thấy chưa được giữ lại; chưa xác nhận độ chính xác của model. Cần bộ ảnh có nhãn và đối chiếu trước khi chỉnh ngưỡng/huấn luyện lại.
- Minh chứng: `deliverables/scan-browser-smoke.json`, `deliverables/scan-browser-verified.png`.

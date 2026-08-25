from flask import Flask, request, jsonify
import cv2
import numpy as np
import base64

app = Flask(__name__)

@app.route('/analyze_skin', methods=['POST'])
def analyze_skin():
    try:
        # 1. Nhận ảnh Base64 từ Flutter gửi lên
        data = request.json
        image_data = data['image_base64']

        # 2. Giải mã ảnh để OpenCV đọc được
        img_bytes = base64.b64decode(image_data)
        np_arr = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        # ==========================================
        # 3. KHU VỰC CHÈN CODE AI CỦA SẾP
        # Dùng MediaPipe khoanh vùng mặt & OpenCV tìm đốm đỏ ở đây
        # Tạm thời trả về dữ liệu thật có cấu trúc để App vẽ
        # ==========================================

        acne_count = 3 # Giả sử AI đếm được 3 cục mụn
        skin_type = "Da Dầu"

        # Tọa độ (top, left) của các cục mụn AI tìm thấy
        acne_coordinates = [
            {"top": 100, "left": 120},
            {"top": 150, "left": 200},
            {"top": 250, "left": 150}
        ]

        # 4. Trả kết quả về cho App Flutter
        return jsonify({
            "status": "success",
            "acne_count": acne_count,
            "skin_type": skin_type,
            "coordinates": acne_coordinates
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

if __name__ == '__main__':
    # Chạy server ở port 5000
    app.run(host='0.0.0.0', port=5000)
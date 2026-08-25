import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Điều khoản dịch vụ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cập nhật lần cuối: Tháng 5/2026",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle("1. Mục đích của ứng dụng"),
            _buildSectionBody(
              "Ứng dụng được thiết kế nhằm hỗ trợ người dùng trong việc chăm sóc sức khỏe làn da một cách cá nhân hóa, thông qua việc phân tích da, gợi ý sản phẩm, theo dõi thói quen và cung cấp các thông tin hữu ích.",
            ),

            _buildSectionTitle("2. Quyền và trách nhiệm của người dùng"),
            _buildBulletPoint(
              "Không sử dụng ứng dụng cho các mục đích vi phạm pháp luật, gian lận hoặc gây ảnh hưởng đến người khác.",
            ),
            _buildBulletPoint(
              "Không sao chép, chỉnh sửa hoặc phân phối ứng dụng khi chưa được sự cho phép.",
            ),
            _buildBulletPoint(
              "Chịu trách nhiệm về mọi hành vi sử dụng tài khoản cá nhân trong ứng dụng.",
            ),

            _buildSectionTitle("3. Quyền và trách nhiệm của chúng tôi"),
            _buildBulletPoint(
              "Chúng tôi có quyền cập nhật, thay đổi hoặc ngừng cung cấp ứng dụng bất kỳ lúc nào mà không cần báo trước.",
            ),
            _buildBulletPoint(
              "Cam kết bảo mật thông tin cá nhân của người dùng theo đúng quy định pháp luật.",
            ),
            _buildBulletPoint(
              "Không chịu trách nhiệm về thiệt hại phát sinh từ việc người dùng sử dụng ứng dụng không đúng mục đích.",
            ),

            _buildSectionTitle("4. Thu thập và xử lý dữ liệu"),
            _buildSectionBody("Ứng dụng có thể thu thập các dữ liệu sau:"),
            _buildBulletPoint(
              "Họ tên, email, số điện thoại (nếu người dùng cung cấp).",
            ),
            _buildBulletPoint("Thông tin loại da, mục tiêu chăm sóc da."),
            _buildBulletPoint(
              "Dữ liệu hành vi sử dụng (click, lượt xem, lịch sử gợi ý...).",
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                "Lưu ý: Dữ liệu được sử dụng để cải thiện trải nghiệm người dùng và cá nhân hóa gợi ý sản phẩm. Chúng tôi cam kết không chia sẻ dữ liệu với bên thứ ba nếu không có sự đồng ý của bạn.",
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

            _buildSectionTitle("5. Chính sách bảo mật & Sở hữu trí tuệ"),
            _buildSectionBody(
              "Chúng tôi sử dụng các biện pháp bảo mật kỹ thuật để đảm bảo dữ liệu cá nhân không bị truy cập trái phép. Người dùng có thể yêu cầu chỉnh sửa hoặc xóa thông tin bất kỳ lúc nào.\n\nTất cả nội dung trong ứng dụng (mã nguồn, hình ảnh, thiết kế...) đều thuộc quyền sở hữu của chúng tôi. Nghiêm cấm sao chép, phân phối lại mà không có sự đồng ý.",
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

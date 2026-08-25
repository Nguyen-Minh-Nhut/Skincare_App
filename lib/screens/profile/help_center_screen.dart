import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:provider/provider.dart'; // THÊM PROVIDER

import '../app_provider.dart'; // IMPORT TỔNG ĐÀI

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    // 2. MÀU SẮC ĐỘNG
    final cardColor = glassSurfaceColor(context);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isEn ? "Help Center" : "Trung tâm trợ giúp",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? "How can we help you?"
                  : "Chúng tôi có thể giúp gì cho bạn?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),

            // Khung Liên hệ CSKH (Luôn giữ nền xanh cho nổi bật)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(
                      alpha: isDark ? 0.1 : 0.3,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isEn
                        ? "Contact Customer Support"
                        : "Liên hệ Chăm sóc khách hàng",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildContactRow(
                    Icons.phone,
                    isEn ? "Toll-free Hotline:" : "Hotline (Miễn phí):",
                    "1900 9999",
                  ),
                  const Divider(color: Colors.white30, height: 20),
                  _buildContactRow(
                    Icons.email,
                    isEn ? "Support Email:" : "Email hỗ trợ:",
                    "support@skincareapp.vn",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Câu hỏi thường gặp khi lỗi
            Text(
              isEn ? "Frequently Asked Questions" : "Câu hỏi thường gặp",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 15),
            _buildFAQItem(
              isEn
                  ? "I can't use the AI Skin Camera?"
                  : "Tôi không thể dùng Camera AI soi da?",
              isEn
                  ? "Please ensure you have granted camera permissions in your phone settings. If the error persists, try restarting the app."
                  : "Hãy đảm bảo bạn đã cấp quyền truy cập Camera cho ứng dụng trong phần Cài đặt của điện thoại. Nếu vẫn lỗi, thử khởi động lại ứng dụng.",
              isDark,
              cardColor,
              textColor,
              subTextColor,
            ),
            _buildFAQItem(
              isEn
                  ? "How to change my Skincare routine?"
                  : "Làm sao để đổi lịch trình Skincare?",
              isEn
                  ? "On the Home tab, tap the pen icon next to 'Your Routine' to customize your skincare steps."
                  : "Tại Trang Chủ, bạn bấm vào biểu tượng cây bút cạnh mục 'Lịch trình của bạn' để tùy chỉnh lại các bước dưỡng da.",
              isDark,
              cardColor,
              textColor,
              subTextColor,
            ),
            _buildFAQItem(
              isEn
                  ? "App crashes during use?"
                  : "Ứng dụng bị văng (Crash) khi dùng?",
              isEn
                  ? "Please check for the latest update on the app store, or contact our Hotline for immediate technical support."
                  : "Vui lòng kiểm tra bản cập nhật mới nhất trên cửa hàng ứng dụng, hoặc liên hệ Hotline để bộ phận kỹ thuật hỗ trợ bạn ngay lập tức.",
              isDark,
              cardColor,
              textColor,
              subTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(
    String question,
    String answer,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textColor,
          ),
        ),
        iconColor: Colors.blueAccent,
        collapsedIconColor: isDark ? Colors.white54 : Colors.black54,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: subTextColor, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

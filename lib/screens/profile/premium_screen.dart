import 'package:flutter/material.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isYearly = true; // Mặc định chọn gói năm cho lợi

  final List<Map<String, dynamic>> _premiumFeatures = [
    {
      "title": "AI Skin Analysis Pro",
      "desc":
          "Không chỉ đếm mụn, AI phân tích sâu về độ ẩm, mức độ lão hóa và tình trạng lỗ chân lông.",
      "icon": Icons.face_retouching_natural,
      "color": Colors.purpleAccent,
    },
    {
      "title": "Ingredient Checker",
      "desc":
          "Quét ảnh bảng thành phần mỹ phẩm. Nhận cảnh báo tức thì nếu có chất gây dị ứng với da bạn.",
      "icon": Icons.document_scanner,
      "color": Colors.teal,
    },
    {
      "title": "Routine Tracker & Reminders",
      "desc":
          "Lập lịch trình chi tiết. App sẽ nhắc nhở: \"Nhựt ơi, tối nay tới lịch dùng Retinol rồi đó!\".",
      "icon": Icons.alarm_on,
      "color": Colors.orangeAccent,
    },
    {
      "title": "Expert Video Call",
      "desc":
          "Kết nối Video Call trực tiếp 1-1 với bác sĩ da liễu và các chuyên gia hàng đầu.",
      "icon": Icons.video_camera_front,
      "color": Colors.blueAccent,
    },
    {
      "title": "Ad-free & Cloud Sync",
      "desc":
          "Trải nghiệm mượt mà không quảng cáo. Sao lưu toàn bộ nhật ký da lên mây vĩnh viễn.",
      "icon": Icons.cloud_done,
      "color": Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildPricingToggle(),
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Đặc quyền hạng VIP",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildFeaturesList(),
                ],
              ),
            ),
          ),
        ],
      ),

      // Nút thanh toán ghim bám đáy màn hình
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang kết nối cổng thanh toán...'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B), // Xanh đen sang trọng
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: const Text(
                "NÂNG CẤP NGAY",
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Header dốc màu Vàng sang chảnh
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1E293B), // Giữ màu nền tối khi cuộn lên
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 50,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Skincare Pro",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Mở khóa toàn bộ sức mạnh AI",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // Công tắc chọn gói Tháng / Năm
  Widget _buildPricingToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isYearly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isYearly
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Text(
                      "1 Tháng",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !_isYearly ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "69.000đ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: !_isYearly
                            ? const Color(0xFF1E293B)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isYearly
                      ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _isYearly
                      ? Border.all(color: const Color(0xFFFFD700), width: 1.5)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      "12 Tháng (Tiết kiệm 30%)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: _isYearly ? Colors.orange.shade800 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "579.000đ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _isYearly ? Colors.orange.shade900 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Danh sách các tính năng VIP
  Widget _buildFeaturesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _premiumFeatures.map((feature) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: feature['color'].withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'],
                    color: feature['color'],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['desc'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

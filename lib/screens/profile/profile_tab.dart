import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'premium_screen.dart';
import 'skin_profile_screen.dart';
import 'scan_history_screen.dart';
import 'wardrobe_screen.dart';
import '../auth/auth_wrapper.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  // Hàm dịch Loại da sang Tiếng Anh
  String _getSkinTypeName(String type, bool isEn) {
    if (!isEn) return type;
    switch (type) {
      case "Chưa xác định":
        return "Unknown";
      case "Da thường":
        return "Normal Skin";
      case "Da dầu":
        return "Oily Skin";
      case "Da khô":
        return "Dry Skin";
      case "Da hỗn hợp":
        return "Combination Skin";
      case "Da nhạy cảm":
        return "Sensitive Skin";
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isPremium =
        user != null &&
        user.email != null &&
        user.email!.startsWith('admin000');

    // 1. LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    // 2. MÀU SẮC ĐỘNG
    final cardColor = glassSurfaceColor(context);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: user == null
            ? Center(
                child: Text(
                  isEn ? "Please login" : "Vui lòng đăng nhập",
                  style: TextStyle(color: textColor),
                ),
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    );
                  }

                  String name =
                      user.displayName ??
                      user.email?.split('@')[0] ??
                      (isEn ? 'You' : 'Bạn');
                  String skinType = "Chưa xác định";
                  String? avatarBase64;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    name = data['name'] ?? name;
                    skinType = data['skinType'] ?? skinType;
                    avatarBase64 = data.containsKey('avatarUrl')
                        ? data['avatarUrl']
                        : null;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // HEADER: Avatar + Thông tin
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: isDark
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.blue.shade100,
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.white,
                                  backgroundImage:
                                      avatarBase64 != null &&
                                          avatarBase64.isNotEmpty
                                      ? MemoryImage(base64Decode(avatarBase64))
                                      : null,
                                  child:
                                      avatarBase64 == null ||
                                          avatarBase64.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.blueAccent,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      isPremium
                                          ? (isEn
                                                ? "Premium Member 👑"
                                                : "Thành viên Premium 👑")
                                          : (isEn ? "Member" : "Thành viên"),
                                      style: TextStyle(
                                        color: isPremium
                                            ? Colors.orange.shade700
                                            : subTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.orange.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _getSkinTypeName(skinType, isEn),
                                        style: TextStyle(
                                          color: Colors.orange.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_square,
                                  color: Colors.blueAccent,
                                  size: 28,
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // STATS
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                "12",
                                isEn ? "Scans" : "Lần soi da",
                                subTextColor,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: dividerColor,
                              ),
                              _buildStatItem(
                                "8",
                                isEn ? "Products" : "Sản phẩm",
                                subTextColor,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: dividerColor,
                              ),
                              _buildStatItem(
                                "450",
                                isEn ? "Points" : "Điểm thưởng",
                                subTextColor,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // PREMIUM BANNER
                        if (!isPremium)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PremiumScreen(),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(
                                      alpha: isDark ? 0.1 : 0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isEn
                                              ? "Upgrade to PREMIUM"
                                              : "Nâng cấp PREMIUM",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isEn
                                              ? "Unlock AI Camera & Ingredient Scanner"
                                              : "Mở khóa Camera AI soi da & Quét thành phần mỹ phẩm",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PremiumScreen(),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.orange.shade800,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      isEn ? "TRY NOW" : "THỬ NGAY",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // MENU ITEMS
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                Icons.face_retouching_natural,
                                Colors.pinkAccent,
                                isEn ? "My Skin Profile" : "Hồ sơ da của tôi",
                                textColor,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SkinProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(height: 1, color: dividerColor),
                              _buildMenuItem(
                                Icons.inventory_2_outlined,
                                Colors.orangeAccent,
                                isEn ? "Skincare Wardrobe" : "Tủ đồ Skincare",
                                textColor,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WardrobeScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(height: 1, color: dividerColor),
                              _buildMenuItem(
                                Icons.history,
                                Colors.green,
                                isEn ? "Scan History" : "Lịch sử soi da",
                                textColor,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ScanHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(height: 1, color: dividerColor),
                              _buildMenuItem(
                                Icons.settings_outlined,
                                isDark ? Colors.white54 : Colors.grey.shade700,
                                isEn ? "General Settings" : "Cài đặt chung",
                                textColor,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(height: 1, color: dividerColor),
                              _buildMenuItem(
                                Icons.logout,
                                Colors.redAccent,
                                isEn ? "Logout" : "Đăng xuất",
                                textColor,
                                () async {
                                  await FirebaseAuth.instance.signOut();
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AuthWrapper(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                isLogout: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color subTextColor) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    Color color,
    String title,
    Color textColor,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isLogout ? Colors.redAccent : textColor,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

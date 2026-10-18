import 'package:flutter/material.dart';
import 'package:skincare_app/widgets/app_icons.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/health_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'skin_profile_screen.dart';
import '../auth/auth_wrapper.dart';
import '../admin/admin_dashboard_screen.dart';

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
                        color: Color(0xFF6264D9),
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
                        HealthPageHeader(
                          title: isEn ? 'Personal' : 'Cá nhân',
                          subtitle: isEn
                              ? 'Your own space for better care.'
                              : 'Không gian chăm sóc dành riêng cho bạn.',
                        ),
                        // PROFILE HERO
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: glassBorderColor(context),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6264D9,
                                ).withValues(alpha: isDark ? 0.10 : 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF7C6CF2),
                                      Color(0xFF56C8E8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 39,
                                  backgroundColor: isDark
                                      ? const Color(0xFF222735)
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
                                          AppIcons.personRounded,
                                          size: 38,
                                          color: Color(0xFF5876E8),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                    const SizedBox(height: 7),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF7C6CF2,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            AppIcons.waterDropRounded,
                                            size: 13,
                                            color: Color(0xFF6E61DC),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _getSkinTypeName(skinType, isEn),
                                            style: const TextStyle(
                                              color: Color(0xFF6E61DC),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      appProvider.isAdmin
                                          ? (isEn
                                                ? "Administrator"
                                                : "Quản trị viên")
                                          : (isEn
                                                ? "Skincare member"
                                                : "Thành viên Skincare"),
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: const Color(
                                  0xFF6264D9,
                                ).withValues(alpha: 0.10),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(
                                    AppIcons.editRounded,
                                    color: Color(0xFF6264D9),
                                    size: 21,
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfileScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        // MENU ITEMS
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: glassBorderColor(context),
                            ),
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
                                AppIcons.faceRetouchingNatural,
                                const Color(0xFF8274DE),
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
                              if (appProvider.isAdmin) ...[
                                Divider(height: 1, color: dividerColor),
                                _buildMenuItem(
                                  AppIcons.adminPanelSettingsOutlined,
                                  Colors.deepPurpleAccent,
                                  isEn ? "Admin dashboard" : "Bảng quản trị",
                                  textColor,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminDashboardScreen(),
                                    ),
                                  ),
                                ),
                              ],
                              Divider(height: 1, color: dividerColor),
                              _buildMenuItem(
                                AppIcons.settingsOutlined,
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
                                AppIcons.logout,
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
        AppIcons.arrowForwardIos,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

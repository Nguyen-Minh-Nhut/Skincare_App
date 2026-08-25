import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_provider.dart';
import 'help_center_screen.dart';
import 'terms_of_service_screen.dart';
import 'scan_history_screen.dart';
// import 'screens/auth/auth_wrapper.dart'; // Đổi đường dẫn theo file Login của sếp

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isNotiEnabled = true;
  bool isPromoEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadFirebaseSettings();
  }

  Future<void> _loadFirebaseSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('notificationsEnabled')) {
        if (mounted) {
          setState(() {
            isNotiEnabled = doc['notificationsEnabled'];
          });
        }
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'notificationsEnabled': value,
      }, SetOptions(merge: true));
    }
    setState(() => isNotiEnabled = value);
  }

  Future<void> _showLanguageDialog(AppProvider appProvider) async {
    final bool currentIsEnglish = appProvider.isEnglish;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        title: const Row(
          children: [
            Icon(Icons.language_rounded, color: Color(0xFF356FE8)),
            SizedBox(width: 10),
            Text(
              'Chọn ngôn ngữ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              dialogContext: dialogContext,
              appProvider: appProvider,
              title: 'Tiếng Việt',
              subtitle: 'Vietnamese',
              flag: '🇻🇳',
              useEnglish: false,
              isSelected: !currentIsEnglish,
            ),
            const SizedBox(height: 4),
            _buildLanguageOption(
              dialogContext: dialogContext,
              appProvider: appProvider,
              title: 'English',
              subtitle: 'Tiếng Anh',
              flag: '🇬🇧',
              useEnglish: true,
              isSelected: currentIsEnglish,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext dialogContext,
    required AppProvider appProvider,
    required String title,
    required String subtitle,
    required String flag,
    required bool useEnglish,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected
          ? const Color(0xFF356FE8).withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Text(flag, style: const TextStyle(fontSize: 27)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(
          isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: isSelected ? const Color(0xFF356FE8) : Colors.grey.shade400,
        ),
        onTap: () async {
          await appProvider.setLanguage(useEnglish);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showDeleteAccountDialog(bool isEn) {
    final TextEditingController passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isEn ? "Delete Account?" : "Xóa tài khoản?",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? "This action cannot be undone. All your skin data will be lost.\n\nEnter your password to confirm."
                      : "Hành động này không thể hoàn tác. Toàn bộ dữ liệu của bạn sẽ bị xóa sạch.\n\nVui lòng nhập mật khẩu để xác nhận.",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isEn ? "Password" : "Mật khẩu",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: Text(
                  isEn ? "Cancel" : "Hủy",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        if (passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEn
                                    ? "Please enter password!"
                                    : "Vui lòng nhập mật khẩu!",
                              ),
                            ),
                          );
                          return;
                        }

                        setStateDialog(() => isDeleting = true);

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && user.email != null) {
                            AuthCredential credential =
                                EmailAuthProvider.credential(
                                  email: user.email!,
                                  password: passwordController.text,
                                );
                            await user.reauthenticateWithCredential(credential);
                            final firestore = FirebaseFirestore.instance;
                            final userRef = firestore
                                .collection('users')
                                .doc(user.uid);
                            final userSnapshot = await userRef.get();
                            final username = userSnapshot
                                .data()?['username']
                                ?.toString();
                            final batch = firestore.batch()..delete(userRef);
                            if (username != null && username.isNotEmpty) {
                              batch.delete(
                                firestore.collection('usernames').doc(username),
                              );
                            }
                            await batch.commit();
                            await user.delete();

                            if (dialogContext.mounted) {
                              final messenger = ScaffoldMessenger.of(
                                dialogContext,
                              );
                              Navigator.pop(dialogContext);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEn
                                        ? "Account deleted."
                                        : "Đã xóa tài khoản.",
                                  ),
                                ),
                              );
                              // Bật dòng dưới lên khi sếp muốn đẩy văng user ra trang đăng nhập
                              // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthWrapper()), (route) => false);
                            }
                          }
                        } on FirebaseAuthException catch (e) {
                          if (!dialogContext.mounted) return;
                          setStateDialog(() => isDeleting = false);
                          String msg = isEn
                              ? "Error occurred."
                              : "Có lỗi xảy ra.";
                          if (e.code == 'wrong-password' ||
                              e.code == 'invalid-credential') {
                            msg = isEn
                                ? "Incorrect password!"
                                : "Mật khẩu không chính xác!";
                          }
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEn ? "DELETE" : "XÓA",
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(passwordController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    // 1. NGHE THEO LỆNH TỪ TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;

    // 2. MÀU SẮC ĐỘNG THEO THEME
    final cardColor = glassSurfaceColor(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(isEn ? 'Settings' : 'Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const SizedBox(height: 10),
          _buildSectionHeader(isEn ? "App Settings" : "Cài đặt ứng dụng"),

          _buildSwitchTile(
            isEn ? "Dark Mode" : "Giao diện tối",
            Icons.dark_mode_outlined,
            appProvider.isDarkMode,
            (val) => appProvider.toggleTheme(),
            cardColor,
          ),

          _buildSwitchTile(
            isEn ? "Daily Skincare Reminders" : "Nhắc nhở Skincare mỗi ngày",
            Icons.notifications_active_outlined,
            isNotiEnabled,
            _toggleNotifications,
            cardColor,
          ),

          _buildSwitchTile(
            isEn ? "Promo Notifications" : "Nhận thông báo khuyến mãi",
            Icons.card_giftcard,
            isPromoEnabled,
            (val) => setState(() => isPromoEnabled = val),
            cardColor,
          ),

          _buildListTile(
            isEn ? "Language / Ngôn ngữ" : "Ngôn ngữ / Language",
            Icons.language,
            trailingText: isEn ? "English" : "Tiếng Việt",
            tileColor: cardColor,
            onTap: () => _showLanguageDialog(appProvider),
          ),

          _buildListTile(
            isEn ? "Skin Scan History" : "Lịch sử soi da",
            Icons.history_rounded,
            tileColor: cardColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanHistoryScreen(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader(
            isEn ? "Account & Privacy" : "Tài khoản & Riêng tư",
          ),
          _buildListTile(
            isEn ? "Change Password" : "Đổi mật khẩu",
            Icons.lock_outline,
            tileColor: cardColor,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEn ? 'Feature in development' : 'Chức năng đang hoàn thiện',
                ),
              ),
            ),
          ),
          _buildListTile(
            isEn ? "Privacy & Reporting" : "Quyền riêng tư & Báo cáo",
            Icons.privacy_tip_outlined,
            tileColor: cardColor,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEn ? 'Privacy settings' : 'Mở trang Quản lý chặn/Báo cáo',
                ),
              ),
            ),
          ),
          _buildListTile(
            isEn ? "Transaction Info" : "Thông tin giao dịch",
            Icons.receipt_long,
            tileColor: cardColor,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEn
                      ? 'No premium history'
                      : 'Chưa có lịch sử giao dịch Premium',
                ),
              ),
            ),
          ),
          _buildListTile(
            isEn ? "Delete Account" : "Xóa tài khoản",
            Icons.person_remove_outlined,
            color: Colors.redAccent,
            tileColor: cardColor,
            onTap: () => _showDeleteAccountDialog(isEn),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader(isEn ? "Support & Info" : "Hỗ trợ & Thông tin"),
          _buildListTile(
            isEn ? "Help Center" : "Trung tâm trợ giúp",
            Icons.help_outline,
            tileColor: cardColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
            ),
          ),
          _buildListTile(
            isEn ? "Rate the App" : "Gửi đánh giá ứng dụng",
            Icons.star_border,
            tileColor: cardColor,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEn ? 'Opening App Store' : 'Mở App Store / Google Play',
                ),
              ),
            ),
          ),
          _buildListTile(
            isEn ? "Terms of Service" : "Điều khoản dịch vụ",
            Icons.description_outlined,
            tileColor: cardColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TermsOfServiceScreen(),
              ),
            ),
          ),

          const SizedBox(height: 30),
          Center(
            child: Text(
              isEn ? "Version 1.0.0 (Beta)" : "Phiên bản 1.0.0 (Beta)",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 10),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color tileColor,
  ) {
    return Container(
      color: tileColor,
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        secondary: Icon(icon, color: Colors.grey.shade500),
        value: value,
        activeThumbColor: Colors.blueAccent,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListTile(
    String title,
    IconData icon, {
    Color? color,
    String? trailingText,
    VoidCallback? onTap,
    required Color tileColor,
  }) {
    return Container(
      color: tileColor,
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.grey.shade500),
        title: Text(title, style: TextStyle(fontSize: 15, color: color)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            if (trailingText != null) const SizedBox(width: 5),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

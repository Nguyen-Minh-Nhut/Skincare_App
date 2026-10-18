import 'package:flutter/material.dart';
import 'package:skincare_app/widgets/app_icons.dart';
import '../../widgets/ambient_background.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_provider.dart';
import 'help_center_screen.dart';
import 'terms_of_service_screen.dart';
import '../../widgets/feature_unavailable.dart';
import '../../services/account_deletion.dart';
import '../auth/auth_wrapper.dart';
import '../auth/password_reset_dialog.dart';

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

  void _showDeleteAccountDialog(bool isEn) {
    final TextEditingController passwordController = TextEditingController();
    bool isDeleting = false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      passwordController.dispose();
      return;
    }
    final needsPassword = AccountDeletion.usesPassword(user);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return PopScope(
            canPop: !isDeleting,
            child: AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  const Icon(
                    AppIcons.warningAmberRounded,
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
                        ? 'Your profile, wardrobe, notifications and scan/chat history on this device will be deleted. Community posts and comments remain. This cannot be undone. ${needsPassword ? "Enter your password to confirm." : "Confirm with your Google account to continue."}'
                        : 'Hồ sơ, tủ đồ, thông báo và lịch sử ảnh/chat trên thiết bị này sẽ bị xóa. Bài viết và bình luận cộng đồng vẫn được giữ lại. Không thể hoàn tác. ${needsPassword ? "Nhập mật khẩu để xác nhận." : "Xác nhận bằng tài khoản Google để tiếp tục."}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  if (needsPassword)
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEn ? "Password" : "Mật khẩu",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(AppIcons.lockOutline),
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
                          if (needsPassword &&
                              passwordController.text.isEmpty) {
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
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            await AccountDeletion.delete(
                              user,
                              passwordController.text,
                            );
                            if (navigator.mounted) {
                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const AuthWrapper(),
                                ),
                                (_) => false,
                              );
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
                            if (e.code == 'cancelled' ||
                                e.code == 'popup-closed-by-user') {
                              msg = isEn
                                  ? 'Confirmation cancelled.'
                                  : 'Đã hủy xác nhận.';
                            } else if (e.code == 'user-mismatch') {
                              msg = isEn
                                  ? 'Choose the Google account you are signed in with.'
                                  : 'Vui lòng chọn đúng tài khoản Google đang đăng nhập.';
                            }
                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(SnackBar(content: Text(msg)));
                          } catch (_) {
                            if (!dialogContext.mounted) return;
                            setStateDialog(() => isDeleting = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEn
                                      ? 'Deletion is incomplete. Check your connection and retry.'
                                      : 'Chưa xóa xong. Kiểm tra kết nối và thử lại.',
                                ),
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
            ),
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
      appBar: AppBar(
        title: Text(
          isEn ? 'Settings' : 'Cài đặt',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            const SizedBox(height: 10),
            _buildSectionHeader(isEn ? "App Settings" : "Cài đặt ứng dụng"),

            _buildSettingsGroup(cardColor, [
              _buildSwitchTile(
                isEn ? "Dark Mode" : "Giao diện tối",
                AppIcons.darkModeRounded,
                appProvider.isDarkMode,
                (val) => appProvider.toggleTheme(),
                const Color(0xFF6558D9),
              ),
              _buildSwitchTile(
                isEn
                    ? "Daily Skincare Reminders"
                    : "Nhắc nhở Skincare mỗi ngày",
                AppIcons.notificationsActiveRounded,
                isNotiEnabled,
                _toggleNotifications,
                const Color(0xFFF39B45),
              ),
              _buildSwitchTile(
                isEn ? "Promo Notifications" : "Nhận thông báo khuyến mãi",
                AppIcons.redeemRounded,
                isPromoEnabled,
                (val) => setState(() => isPromoEnabled = val),
                const Color(0xFFEC6A91),
              ),
              _buildLanguageMenu(appProvider, isEn),
              _buildListTile(
                isEn ? "Skin Scan History" : "Lịch sử soi da",
                AppIcons.historyRounded,
                iconColor: const Color(0xFF43A879),
                onTap: () => showFeatureUnavailable(context, isEnglish: isEn),
              ),
            ]),

            const SizedBox(height: 20),
            _buildSectionHeader(
              isEn ? "Account & Privacy" : "Tài khoản & Riêng tư",
            ),
            _buildSettingsGroup(cardColor, [
              _buildListTile(
                isEn ? "Reset password" : "Đặt lại mật khẩu",
                AppIcons.lockRounded,
                iconColor: const Color(0xFF6558D9),
                onTap: () => showPasswordResetDialog(
                  context,
                  initialEmail: FirebaseAuth.instance.currentUser?.email ?? '',
                  isEnglish: isEn,
                ),
              ),
              _buildListTile(
                isEn ? "Privacy & Reporting" : "Quyền riêng tư & Báo cáo",
                AppIcons.shieldRounded,
                iconColor: const Color(0xFF399BC8),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEn
                          ? 'Privacy settings'
                          : 'Mở trang Quản lý chặn/Báo cáo',
                    ),
                  ),
                ),
              ),
              _buildListTile(
                isEn ? "Transaction Info" : "Thông tin giao dịch",
                AppIcons.receiptLongRounded,
                iconColor: const Color(0xFFF39B45),
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
                AppIcons.personRemoveOutlined,
                color: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: () => _showDeleteAccountDialog(isEn),
              ),
            ]),

            const SizedBox(height: 20),
            _buildSectionHeader(isEn ? "Support & Info" : "Hỗ trợ & Thông tin"),
            _buildSettingsGroup(cardColor, [
              _buildListTile(
                isEn ? "Help Center" : "Trung tâm trợ giúp",
                AppIcons.helpRounded,
                iconColor: const Color(0xFF399BC8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpCenterScreen(),
                  ),
                ),
              ),
              _buildListTile(
                isEn ? "Rate the App" : "Gửi đánh giá ứng dụng",
                AppIcons.starRounded,
                iconColor: const Color(0xFFF4A340),
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
                AppIcons.descriptionRounded,
                iconColor: const Color(0xFF6558D9),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen(),
                  ),
                ),
              ),
            ]),

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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 22, bottom: 10, top: 14),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color iconColor,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      secondary: _buildIcon(icon, iconColor),
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: const Color(0xFF6558D9),
      onChanged: onChanged,
    );
  }

  Widget _buildLanguageMenu(AppProvider appProvider, bool isEn) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuColor = isDark
        ? const Color(0xFF242938)
        : const Color(0xFFFFFFFF);

    return PopupMenuButton<String>(
      color: menuColor,
      elevation: 14,
      position: PopupMenuPosition.under,
      offset: const Offset(12, -4),
      constraints: const BoxConstraints(minWidth: 230),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE3E7EF),
        ),
      ),
      onSelected: appProvider.setLanguageCode,
      itemBuilder: (context) => [
        _languageMenuItem(
          value: 'vi',
          code: 'VI',
          title: 'Tiếng Việt',
          subtitle: 'Vietnamese',
          isSelected: appProvider.languageCode == 'vi',
          isDark: isDark,
        ),
        _languageMenuItem(
          value: 'en',
          code: 'EN',
          title: 'English',
          subtitle: 'Tiếng Anh',
          isSelected: appProvider.languageCode == 'en',
          isDark: isDark,
        ),
        _languageMenuItem(
          value: 'ko',
          code: 'KO',
          title: '한국어',
          subtitle: 'Korean',
          isSelected: appProvider.languageCode == 'ko',
          isDark: isDark,
        ),
        _languageMenuItem(
          value: 'zh-Hans',
          code: 'ZH',
          title: '简体中文',
          subtitle: 'Simplified Chinese',
          isSelected: appProvider.languageCode == 'zh-Hans',
          isDark: isDark,
        ),
      ],
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: _buildIcon(AppIcons.languageRounded, const Color(0xFF399BC8)),
        title: Text(
          isEn ? 'Language / Ngôn ngữ' : 'Ngôn ngữ / Language',
          style: const TextStyle(fontSize: 15),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageCodeBadge(switch (appProvider.languageCode) {
              'ko' => 'KO',
              'zh-Hans' => 'ZH',
              'en' => 'EN',
              _ => 'VI',
            }, selected: true),
            const SizedBox(width: 8),
            const Icon(AppIcons.expandMore, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _languageMenuItem({
    required String value,
    required String code,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 64,
      child: Row(
        children: [
          _languageCodeBadge(code, selected: isSelected),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF20232D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              AppIcons.checkCircleRounded,
              color: Color(0xFF356FE8),
              size: 21,
            ),
        ],
      ),
    );
  }

  Widget _languageCodeBadge(String code, {required bool selected}) => Container(
    width: 36,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: selected ? const Color(0xFF356FE8) : const Color(0xFFF0F3F8),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      code,
      style: TextStyle(
        color: selected ? Colors.white : const Color(0xFF596273),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildListTile(
    String title,
    IconData icon, {
    Color? color,
    Color? iconColor,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: _buildIcon(icon, iconColor ?? color ?? Colors.grey.shade500),
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
          const Icon(AppIcons.arrowForwardIos, size: 14, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildIcon(IconData icon, Color color) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 20),
  );

  Widget _buildSettingsGroup(Color color, List<Widget> children) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: glassBorderColor(context)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        for (int index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            Divider(height: 1, indent: 66, color: glassBorderColor(context)),
        ],
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

enum AppLanguage {
  vietnamese('vi'),
  english('en'),
  korean('ko'),
  simplifiedChinese('zh-Hans');

  const AppLanguage(this.code);
  final String code;

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
    (language) => language.code == code,
    orElse: () => AppLanguage.vietnamese,
  );
}

class AppProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.vietnamese;
  bool _isDarkMode = false;
  bool _isAdmin = false;
  StreamSubscription<User?>? _authSubscription;

  AppLanguage get language => _language;
  String get languageCode => _language.code;

  /// Screens awaiting Korean/Chinese copy use English instead of unexpectedly
  /// falling back to Vietnamese.
  bool get isEnglish => _language != AppLanguage.vietnamese;
  bool get isDarkMode => _isDarkMode;
  bool get isAdmin => _isAdmin;

  AppProvider() {
    _loadPreferences();
    _watchAdminClaim();
  }

  void _watchAdminClaim() {
    try {
      _authSubscription = FirebaseAuth.instance.idTokenChanges().listen(
        _refreshAdminClaim,
      );
    } catch (_) {
      // Firebase có thể chưa được khởi tạo trong unit test.
    }
  }

  Future<void> _refreshAdminClaim(User? user) async {
    var nextValue = false;
    if (user != null) {
      try {
        final token = await user.getIdTokenResult(true);
        nextValue = token.claims?['admin'] == true;
      } catch (_) {
        nextValue = false;
      }
    }
    if (_isAdmin == nextValue) return;
    _isAdmin = nextValue;
    notifyListeners();
  }

  // Tự động load cài đặt cũ khi mở app
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('languageCode');
    if (savedLanguage != null) {
      _language = AppLanguage.fromCode(savedLanguage);
    } else {
      // Migrate the previous two-language preference without losing selection.
      _language = prefs.getBool('isEnglish') == true
          ? AppLanguage.english
          : AppLanguage.vietnamese;
    }
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners(); // Báo cho toàn app biết để vẽ lại
  }

  // Hàm đổi ngôn ngữ
  Future<void> toggleLanguage() async {
    await setLanguage(isEnglish ? false : true);
  }

  Future<void> setLanguage(bool useEnglish) async {
    await setLanguageCode(useEnglish ? 'en' : 'vi');
  }

  Future<void> setLanguageCode(String code) async {
    final nextLanguage = AppLanguage.fromCode(code);
    if (_language == nextLanguage) return;
    _language = nextLanguage;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', _language.code);
    // Keep the old key in sync for backward compatibility.
    await prefs.setBool('isEnglish', isEnglish);
    notifyListeners(); // Kêu toàn app đổi chữ!
  }

  // Hàm bật/tắt Dark Mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners(); // Kêu toàn app tắt đèn!
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

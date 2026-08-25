import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  bool _isEnglish = false;
  bool _isDarkMode = false;

  bool get isEnglish => _isEnglish;
  bool get isDarkMode => _isDarkMode;

  AppProvider() {
    _loadPreferences();
  }

  // Tự động load cài đặt cũ khi mở app
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('isEnglish') ?? false;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners(); // Báo cho toàn app biết để vẽ lại
  }

  // Hàm đổi ngôn ngữ
  Future<void> toggleLanguage() async {
    await setLanguage(!_isEnglish);
  }

  Future<void> setLanguage(bool useEnglish) async {
    if (_isEnglish == useEnglish) return;
    _isEnglish = useEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', _isEnglish);
    notifyListeners(); // Kêu toàn app đổi chữ!
  }

  // Hàm bật/tắt Dark Mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners(); // Kêu toàn app tắt đèn!
  }
}

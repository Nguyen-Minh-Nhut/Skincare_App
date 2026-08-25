import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_app/screens/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppProvider loads saved preferences', () async {
    SharedPreferences.setMockInitialValues({
      'isEnglish': true,
      'isDarkMode': true,
    });

    final provider = AppProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.isEnglish, isTrue);
    expect(provider.isDarkMode, isTrue);
  });

  test('AppProvider toggles and persists settings', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.toggleLanguage();
    await provider.toggleTheme();

    final preferences = await SharedPreferences.getInstance();
    expect(provider.isEnglish, isTrue);
    expect(provider.isDarkMode, isTrue);
    expect(preferences.getBool('isEnglish'), isTrue);
    expect(preferences.getBool('isDarkMode'), isTrue);
  });

  test('AppProvider selects and persists an explicit language', () async {
    SharedPreferences.setMockInitialValues({'isEnglish': true});
    final provider = AppProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.setLanguage(false);

    final preferences = await SharedPreferences.getInstance();
    expect(provider.isEnglish, isFalse);
    expect(preferences.getBool('isEnglish'), isFalse);
  });
}

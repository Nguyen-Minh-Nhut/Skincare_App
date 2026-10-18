import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/app_provider.dart';
import 'widgets/ambient_background.dart';
import 'theme/health_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // BỌC PROVIDER Ở ĐÂY ĐỂ TOÀN APP ĐỀU NGHE ĐƯỢC
    ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // LẮNG NGHE LỆNH TỪ TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);

    return MaterialApp(
      title: 'Skincare App',
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          AmbientBackground(child: child ?? const SizedBox.shrink()),

      // TỰ ĐỘNG CHUYỂN SÁNG/TỐI DỰA VÀO NÚT BẤM
      themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: healthTheme(Brightness.light),
      darkTheme: healthTheme(Brightness.dark),
      home: const AuthWrapper(),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/health_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'home/home_tag.dart';
import 'suggestions/suggestions_tab.dart';
import 'profile/profile_tab.dart';
import 'home/scan_landing_screen.dart';
import '../widgets/care_routine_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AppTab { home, camera, suggestions, profile }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AppTab selectedTab = AppTab.home;
  final List<Widget?> _tabPages = List<Widget?>.filled(
    AppTab.values.length,
    null,
  );

  Widget _createTab(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return HomeTab(
          onOpenScan: () => setState(() => selectedTab = AppTab.camera),
          onOpenCare: () => setState(() => selectedTab = AppTab.suggestions),
        );
      case AppTab.suggestions:
        return const SuggestionsTab();
      case AppTab.camera:
        return const ScanLandingScreen();
      case AppTab.profile:
        return const ProfileTab();
    }
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => CareRoutineModel(
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
    ),
    child: Builder(builder: _buildShell),
  );

  Widget _buildShell(BuildContext context) {
    // LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildBodyContent(),
              ),
            ),
          ),
          // THANH ĐIỀU HƯỚNG BÁM ĐÁY (STYLE DRIBBBLE)
          Positioned(
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            left: 20,
            right: 20,
            child: HealthNavigationBar(
              selectedIndex: selectedTab.index,
              isDark: isDark,
              isEnglish: appProvider.isEnglish,
              onSelected: (index) =>
                  setState(() => selectedTab = AppTab.values[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    final selectedIndex = AppTab.values.indexOf(selectedTab);
    _tabPages[selectedIndex] ??= _createTab(selectedTab);
    return IndexedStack(
      index: selectedIndex,
      children: List.generate(
        AppTab.values.length,
        (index) => _tabPages[index] ?? const SizedBox.shrink(),
      ),
    );
  }
}

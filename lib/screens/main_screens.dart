import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'home/home_tag.dart';
import 'suggestions/suggestions_tab.dart';
import 'consult/consult_tab.dart';
import 'profile/profile_tab.dart';
import 'home/ai_camera_tab.dart';
import 'dart:ui';

enum AppTab { home, suggestions, camera, consult, profile }

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
        return const HomeTab();
      case AppTab.suggestions:
        return const SuggestionsTab();
      case AppTab.camera:
        return const AiCameraTab();
      case AppTab.consult:
        return const ConsultTab();
      case AppTab.profile:
        return const ProfileTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    // LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(bottom: false, child: _buildBodyContent()),
          // THANH ĐIỀU HƯỚNG BÁM ĐÁY (STYLE DRIBBBLE)
          Positioned(
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            left: 20,
            right: 20,
            child: _buildCustomBottomNavBar(isDark),
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

  Widget _buildCustomBottomNavBar(bool isDark) {
    final selectedIndex = AppTab.values.indexOf(selectedTab);

    final double navBarWidth = MediaQuery.of(context).size.width - 40;
    final double tabWidth = navBarWidth / 5;

    // ===== GLASS COLORS =====
    final Color glassColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.58);

    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.72);

    final Color inactiveIconColor = isDark
        ? Colors.white.withValues(alpha: 0.48)
        : const Color(0xFFB7B7B7);

    final Color activeCircleColor = isDark
        ? const Color(0xFF3E78FF)
        : const Color(0xFF356FE8);

    final Color shadowColor = Colors.black.withValues(
      alpha: isDark ? 0.30 : 0.10,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(38),
      child: BackdropFilter(
        // ===== GLASS BLUR =====
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 70,

          decoration: BoxDecoration(
            // ===== GLASS BACKGROUND =====
            color: glassColor,

            // ===== VIỀN KÍNH =====
            border: Border.all(color: borderColor, width: 1),

            borderRadius: BorderRadius.circular(38),

            // ===== SHADOW =====
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: Stack(
            children: [
              // ============================================================
              // ACTIVE CIRCLE
              // ============================================================
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,

                left: selectedIndex * tabWidth,
                top: 0,
                bottom: 0,

                child: SizedBox(
                  width: tabWidth,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,

                      width: 50,
                      height: 50,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeCircleColor,

                        boxShadow: [
                          BoxShadow(
                            color: activeCircleColor.withValues(alpha: 0.18),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ============================================================
              // ICONS
              // ============================================================
              Row(
                children: [
                  _buildNavItem(
                    Icons.home_outlined,
                    Icons.home_rounded,
                    AppTab.home,
                    inactiveIconColor,
                  ),

                  _buildNavItem(
                    Icons.tips_and_updates_outlined,
                    Icons.tips_and_updates_rounded,
                    AppTab.suggestions,
                    inactiveIconColor,
                  ),

                  _buildNavItem(
                    Icons.face_retouching_natural_outlined,
                    Icons.face_retouching_natural_rounded,
                    AppTab.camera,
                    inactiveIconColor,
                  ),

                  _buildNavItem(
                    Icons.forum_outlined,
                    Icons.forum_rounded,
                    AppTab.consult,
                    inactiveIconColor,
                  ),

                  _buildNavItem(
                    Icons.person_outline,
                    Icons.person_rounded,
                    AppTab.profile,
                    inactiveIconColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    AppTab tab,
    Color inactiveColor,
  ) {
    final bool isActive = selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = tab;
          });
        },
        behavior: HitTestBehavior.opaque,

        child: SizedBox(
          height: 70,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),

              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,

              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },

              child: Icon(
                isActive ? activeIcon : icon,

                key: ValueKey('${tab.name}-$isActive'),

                color: isActive ? Colors.white : inactiveColor,

                size: isActive ? 26 : 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';

/// Navigation shared by the live app; page state remains owned by MainScreen.
class HealthNavigationBar extends StatelessWidget {
  const HealthNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.isEnglish,
    required this.isDark,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isEnglish;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6264D9);
    final labels = isEnglish
        ? ['Today', 'Skin tracking', 'Care', 'Personal']
        : ['Hôm nay', 'Theo dõi da', 'Chăm sóc', 'Cá nhân'];
    const icons = [
      Icons.favorite_outline,
      Icons.document_scanner_outlined,
      Icons.wb_twilight_outlined,
      Icons.person_outline,
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: (isDark ? const Color(0xFF232330) : Colors.white)
                  .withValues(alpha: .94),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: List.generate(
                    labels.length,
                    (i) => Expanded(
                      child: Semantics(
                        selected: selectedIndex == i,
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () => onSelected(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              vertical: 11,
                              horizontal: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: selectedIndex == i
                                  ? (isDark
                                        ? const Color(0xFF373451)
                                        : const Color(0xFFEAE9FC))
                                  : Colors.transparent,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icons[i],
                                  size: 24,
                                  color: selectedIndex == i
                                      ? (isDark
                                            ? const Color(0xFFB8B5FF)
                                            : accent)
                                      : (isDark
                                            ? Colors.white70
                                            : const Color(0xFF474752)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  labels[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: selectedIndex == i
                                        ? (isDark
                                              ? const Color(0xFFB8B5FF)
                                              : accent)
                                        : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF474752)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

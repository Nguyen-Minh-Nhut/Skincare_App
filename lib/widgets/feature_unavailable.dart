import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:skincare_app/widgets/app_icons.dart';

void showFeatureUnavailable(BuildContext context, {required bool isEnglish}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        isEnglish
            ? 'This feature is temporarily locked while it is being completed.'
            : 'Tính năng này đang tạm khóa trong lúc hoàn thiện.',
      ),
      showCloseIcon: true,
    ),
  );
}

class FeatureUnavailableScreen extends StatelessWidget {
  const FeatureUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.lockClockOutlined,
                    size: 54,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEnglish
                        ? 'Temporarily unavailable'
                        : 'Tạm thời chưa khả dụng',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEnglish
                        ? 'Acne scanning is being completed and tested before release.'
                        : 'Quét mụn đang được hoàn thiện và kiểm thử trước khi mở lại.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';

Color glassSurfaceColor(BuildContext context, {double? opacity}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return (isDark ? const Color(0xFF171B27) : Colors.white).withValues(
    alpha: opacity ?? (isDark ? 0.64 : 0.62),
  );
}

Color glassBorderColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Colors.white.withValues(alpha: isDark ? 0.14 : 0.58);
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.opacity,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? opacity;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: glassSurfaceColor(context, opacity: opacity),
          borderRadius: borderRadius,
          border: Border.all(color: glassBorderColor(context)),
        ),
        child: child,
      ),
    ),
  );
}

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? const Color(0xFF10131B) : const Color(0xFFF4F7FF),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _AmbientOrb(
            alignment: Alignment(1.25, -0.82),
            size: 330,
            lightColor: Color(0xFF9688FF),
            darkColor: Color(0xFF5143A5),
          ),
          const _AmbientOrb(
            alignment: Alignment(-1.35, 0.08),
            size: 390,
            lightColor: Color(0xFF67C7F5),
            darkColor: Color(0xFF155A82),
          ),
          const _AmbientOrb(
            alignment: Alignment(1.30, 0.94),
            size: 350,
            lightColor: Color(0xFFF0A5D2),
            darkColor: Color(0xFF743A68),
          ),
          child,
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.alignment,
    required this.size,
    required this.lightColor,
    required this.darkColor,
  });

  final Alignment alignment;
  final double size;
  final Color lightColor;
  final Color darkColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? darkColor : lightColor).withValues(
                alpha: isDark ? 0.24 : 0.30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

Color glassSurfaceColor(BuildContext context, {double? opacity}) =>
    Theme.of(context).colorScheme.surface.withValues(alpha: opacity ?? 1);

Color glassBorderColor(BuildContext context) => Colors.transparent;

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.margin,
    this.opacity,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? opacity;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: glassSurfaceColor(context, opacity: opacity),
        borderRadius: borderRadius,
      ),
      child: child,
    ),
  );
}

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF131725), Color(0xFF191B2C), Color(0xFF12212B)]
              : const [Color(0xFFF2F6FF), Color(0xFFF6F4FF), Color(0xFFEDF8FF)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _glow(
            const Alignment(1.1, -.7),
            dark ? const Color(0xFF7064C8) : const Color(0xFFA79AF4),
            dark ? .14 : .22,
          ),
          _glow(
            const Alignment(-1.15, .65),
            dark ? const Color(0xFF399BC4) : const Color(0xFF7DCDF4),
            dark ? .16 : .30,
          ),
          child,
        ],
      ),
    );
  }

  Widget _glow(Alignment alignment, Color color, double opacity) =>
      IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: alignment,
              radius: 1.1,
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 1],
            ),
          ),
        ),
      );
}

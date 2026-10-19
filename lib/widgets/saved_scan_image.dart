import 'dart:io';
import 'package:flutter/material.dart';
import '../screens/home/scan_history.dart';

class SavedScanImage extends StatelessWidget {
  const SavedScanImage({super.key, required this.scan});
  final SavedScan scan;
  @override
  Widget build(BuildContext context) {
    final width = scan.imageWidth, height = scan.imageHeight;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return Image.file(File(scan.imagePath), height: 300, fit: BoxFit.contain);
    }
    return AspectRatio(
      aspectRatio: width / height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(scan.imagePath), fit: BoxFit.contain),
          CustomPaint(
            painter: SavedRegionsPainter(
              regions: scan.regions,
              imageWidth: width.toDouble(),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedRegionsPainter extends CustomPainter {
  const SavedRegionsPainter({required this.regions, required this.imageWidth});
  final List<Map<String, double>> regions;
  final double imageWidth;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / imageWidth;
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final r in regions) {
      canvas.drawRect(
        Rect.fromLTWH(
          r['left']! * scale,
          r['top']! * scale,
          r['width']! * scale,
          r['height']! * scale,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SavedRegionsPainter oldDelegate) =>
      oldDelegate.regions != regions || oldDelegate.imageWidth != imageWidth;
}

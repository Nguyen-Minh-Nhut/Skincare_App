import 'package:flutter/services.dart';

/// These are capture heuristics, not measurements of skin condition.
String? scanFaceIssue(List<Map<String, dynamic>> faces) {
  if (faces.isEmpty) return 'no-face';
  if (faces.length != 1) return 'multiple-faces';
  final face = faces.single;
  final roll = (face['roll'] as num?)?.toDouble();
  final yaw = (face['yaw'] as num?)?.toDouble();
  final pitch = (face['pitch'] as num?)?.toDouble();
  final width = (face['widthFraction'] as num?)?.toDouble();
  if ([
    roll,
    yaw,
    pitch,
    width,
  ].any((value) => value == null || !value.isFinite)) {
    return 'check-failed';
  }
  if (roll!.abs() > 30 || yaw!.abs() > 45 || pitch!.abs() > 35) {
    return 'face-angle';
  }
  if (width! < .2) return 'face-small';
  return null;
}

class ScanInputCheck {
  static const _channel = MethodChannel('meowskin/scan_input');
  Future<String?> validate(Uint8List normalizedJpeg) async {
    final faces = await _channel.invokeListMethod<dynamic>('faces', {
      'bytes': normalizedJpeg,
    });
    if (faces == null) return 'check-failed';
    return scanFaceIssue(
      faces.map((face) => Map<String, dynamic>.from(face as Map)).toList(),
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedScan {
  const SavedScan({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.createdAt,
    required this.acneCount,
    required this.level,
    required this.morningRoutine,
    required this.nightRoutine,
    required this.activeIngredients,
    required this.warning,
  });

  final String id;
  final String userId;
  final String imagePath;
  final DateTime createdAt;
  final int acneCount;
  final String level;
  final String morningRoutine;
  final String nightRoutine;
  final String activeIngredients;
  final String warning;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
    'acneCount': acneCount,
    'level': level,
    'morningRoutine': morningRoutine,
    'nightRoutine': nightRoutine,
    'activeIngredients': activeIngredients,
    'warning': warning,
  };

  factory SavedScan.fromJson(Map<String, dynamic> json) => SavedScan(
    id: json['id'] as String,
    userId: json['userId'] as String? ?? '',
    imagePath: json['imagePath'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    acneCount: json['acneCount'] as int,
    level: json['level'] as String,
    morningRoutine: json['morningRoutine'] as String,
    nightRoutine: json['nightRoutine'] as String,
    activeIngredients: json['activeIngredients'] as String,
    warning: json['warning'] as String,
  );
}

class ScanHistoryStore {
  static const _storageKey = 'saved_skin_scans_v1';

  static Future<List<SavedScan>> load({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_storageKey) ?? const [];
    final scans = <SavedScan>[];
    for (final raw in rawItems) {
      try {
        final scan = SavedScan.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (scan.userId == userId && File(scan.imagePath).existsSync()) {
          scans.add(scan);
        }
      } catch (_) {
        // Bỏ qua bản ghi cũ/hỏng thay vì làm hỏng toàn bộ lịch sử.
      }
    }
    scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return scans;
  }

  static Future<SavedScan> save({
    required String userId,
    required File sourceImage,
    required int acneCount,
    required String level,
    required String morningRoutine,
    required String nightRoutine,
    required String activeIngredients,
    required String warning,
  }) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final appDirectory = await getApplicationDocumentsDirectory();
    final scanDirectory = Directory('${appDirectory.path}/skin_scans');
    await scanDirectory.create(recursive: true);
    final extension = sourceImage.path.toLowerCase().endsWith('.png')
        ? 'png'
        : 'jpg';
    final savedImage = await sourceImage.copy(
      '${scanDirectory.path}/scan_$id.$extension',
    );
    final scan = SavedScan(
      id: id,
      userId: userId,
      imagePath: savedImage.path,
      createdAt: now,
      acneCount: acneCount,
      level: level,
      morningRoutine: morningRoutine,
      nightRoutine: nightRoutine,
      activeIngredients: activeIngredients,
      warning: warning,
    );
    final prefs = await SharedPreferences.getInstance();
    final items = [...prefs.getStringList(_storageKey) ?? const <String>[]];
    items.add(jsonEncode(scan.toJson()));
    await prefs.setStringList(_storageKey, items);
    return scan;
  }

  static Future<void> delete(SavedScan scan) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_storageKey) ?? const [];
    final retained = items.where((raw) {
      try {
        return (jsonDecode(raw) as Map<String, dynamic>)['id'] != scan.id;
      } catch (_) {
        return false;
      }
    }).toList();
    await prefs.setStringList(_storageKey, retained);
    final image = File(scan.imagePath);
    if (await image.exists()) await image.delete();
  }
}

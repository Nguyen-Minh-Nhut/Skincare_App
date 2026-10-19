import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';

import '../home/scan_history.dart';
import '../../widgets/saved_scan_image.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  late Future<List<SavedScan>> _scans;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _scans = ScanHistoryStore.load(
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
    );
  }

  bool get _isEn => context.read<AppProvider>().isEnglish;

  Future<void> _delete(SavedScan scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEn ? 'Delete scan?' : 'Xóa kết quả soi da?'),
        content: Text(
          _isEn
              ? 'This saved result and photo will be permanently deleted.'
              : 'Kết quả và ảnh đã lưu sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_isEn ? 'Cancel' : 'Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isEn ? 'Delete' : 'Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ScanHistoryStore.delete(scan);
      if (mounted) setState(_reload);
    } catch (_) {
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEn
                ? 'Could not finish deleting. Please retry.'
                : 'Chưa xóa hoàn tất. Vui lòng thử lại.',
          ),
        ),
      );
    }
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(_isEn ? 'Scan history' : 'Lịch sử soi da')),
      body: FutureBuilder<List<SavedScan>>(
        future: _scans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isEn
                        ? 'Could not load scan history.'
                        : 'Không tải được lịch sử soi da.',
                  ),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: Text(_isEn ? 'Retry' : 'Thử lại'),
                  ),
                ],
              ),
            );
          }
          final scans = snapshot.data ?? const [];
          if (scans.isEmpty) {
            return Center(
              child: Text(
                _isEn
                    ? 'No saved scans yet.'
                    : 'Chưa có kết quả soi da nào được lưu.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scans.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final scan = scans[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(scan.imagePath),
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 68,
                        height: 68,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  title: Text(
                    '${scan.acneCount} ${_isEn ? 'spots' : 'nốt'} • ${scan.level}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_date(scan.createdAt)),
                  trailing: IconButton(
                    tooltip: _isEn ? 'Delete scan' : 'Xóa kết quả',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(scan),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _SavedScanDetail(scan: scan),
                    ),
                  ),
                  onLongPress: () => _delete(scan),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SavedScanDetail extends StatelessWidget {
  const _SavedScanDetail({required this.scan});
  final SavedScan scan;

  Widget _row(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 15, height: 1.45),
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<AppProvider>().isEnglish;
    return Scaffold(
      appBar: AppBar(title: Text(isEn ? 'Scan result' : 'Kết quả soi da')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SavedScanImage(scan: scan),
          ),
          const SizedBox(height: 20),
          Text(
            isEn
                ? '${scan.acneCount} spots detected'
                : '${scan.acneCount} nốt được phát hiện',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          _row(isEn ? 'Assessment' : 'Đánh giá', scan.level),
          if (scan.morningRoutine.isNotEmpty)
            _row(isEn ? 'Morning' : 'Buổi sáng', scan.morningRoutine),
          if (scan.nightRoutine.isNotEmpty)
            _row(isEn ? 'Evening' : 'Buổi tối', scan.nightRoutine),
          if (scan.activeIngredients.isNotEmpty)
            _row(
              isEn ? 'Suggested ingredients' : 'Hoạt chất khuyên dùng',
              scan.activeIngredients,
            ),
          _row(isEn ? 'Notes' : 'Lưu ý', scan.warning),
        ],
      ),
    );
  }
}

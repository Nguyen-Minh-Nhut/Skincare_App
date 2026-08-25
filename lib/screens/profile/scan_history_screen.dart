import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/scan_history.dart';

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

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử soi da')),
      body: FutureBuilder<List<SavedScan>>(
        future: _scans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final scans = snapshot.data ?? const [];
          if (scans.isEmpty) {
            return const Center(
              child: Text('Chưa có kết quả soi da nào được lưu.'),
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
                    ),
                  ),
                  title: Text(
                    '${scan.acneCount} nốt • ${scan.level}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_date(scan.createdAt)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _SavedScanDetail(scan: scan),
                    ),
                  ),
                  onLongPress: () async {
                    await ScanHistoryStore.delete(scan);
                    if (!mounted) return;
                    setState(_reload);
                  },
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kết quả soi da')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            File(scan.imagePath),
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${scan.acneCount} nốt được phát hiện',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        _row('Đánh giá', scan.level),
        _row('Buổi sáng', scan.morningRoutine),
        _row('Buổi tối', scan.nightRoutine),
        _row('Hoạt chất khuyên dùng', scan.activeIngredients),
        _row('Lưu ý', scan.warning),
      ],
    ),
  );
}

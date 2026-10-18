import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../profile/scan_history_screen.dart';
import '../../widgets/health_page.dart';
import '../../widgets/care_routine_card.dart';
import 'scan_history.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.onOpenScan,
    required this.onOpenCare,
  });
  final VoidCallback onOpenScan;
  final VoidCallback onOpenCare;
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<SavedScan> _scans = const [];
  bool _loading = true;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final scans = uid == null
          ? <SavedScan>[]
          : await ScanHistoryStore.load(userId: uid);
      if (mounted) setState(() => _scans = scans);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _history() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanHistoryScreen()),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final en = context.watch<AppProvider>().isEnglish;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 130),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          HealthPageHeader(
            title: en ? 'Today' : 'Hôm nay',
            subtitle: en
                ? 'A little care, every day.'
                : 'Một chút chăm sóc, mỗi ngày.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  en ? 'Your latest result' : 'Kết quả gần nhất',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (_failed)
                  HealthCard(
                    child: Column(
                      children: [
                        Text(
                          en
                              ? 'Could not load saved scans.'
                              : 'Chưa tải được lịch sử soi da.',
                        ),
                        TextButton(
                          onPressed: _load,
                          child: Text(en ? 'Retry' : 'Thử lại'),
                        ),
                      ],
                    ),
                  ),
                if (!_loading && !_failed)
                  HealthCard(
                    onTap: _history,
                    child: Text(
                      _scans.isEmpty
                          ? (en
                                ? 'No saved results yet. AI scanning is under maintenance.'
                                : 'Chưa có kết quả đã lưu. Quét AI đang bảo trì.')
                          : (en
                                ? '${_scans.first.acneCount} spots detected · ${_scans.first.createdAt.day}/${_scans.first.createdAt.month}/${_scans.first.createdAt.year}'
                                : '${_scans.first.acneCount} nốt được phát hiện · ${_scans.first.createdAt.day}/${_scans.first.createdAt.month}/${_scans.first.createdAt.year}'),
                    ),
                  ),
                const SizedBox(height: 12),
                HealthCard(
                  onTap: widget.onOpenScan,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.document_scanner_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              en ? 'Skin tracking' : 'Theo dõi da',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              en
                                  ? 'Saved results and trends · AI scanning under maintenance'
                                  : 'Lịch sử và thay đổi của da · Quét AI đang bảo trì',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: healthAccent,
                        size: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  en ? 'For today' : 'Dành cho hôm nay',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                CareRoutineCard(
                  isEnglish: en,
                  compact: true,
                  onOpenCare: widget.onOpenCare,
                ),
                const SizedBox(height: 26),
                Center(
                  child: Text(
                    en
                        ? 'A little kindness for your skin.'
                        : 'Dành một chút dịu dàng cho làn da bạn.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

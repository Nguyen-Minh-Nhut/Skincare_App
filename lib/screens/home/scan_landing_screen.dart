import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scan_history.dart';
import '../../widgets/scan_trend_card.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../profile/scan_history_screen.dart';
import '../../widgets/health_page.dart';

/// Live version of the preview scan page. The detector remains under maintenance.
class ScanLandingScreen extends StatefulWidget {
  const ScanLandingScreen({super.key});
  @override
  State<ScanLandingScreen> createState() => _ScanLandingScreenState();
}

class _ScanLandingScreenState extends State<ScanLandingScreen> {
  List<SavedScan> _scans = [];
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
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 130),
        children: [
          HealthPageHeader(
            title: en ? 'Skin tracking' : 'Theo dõi da',
            subtitle: en
                ? 'Meet your skin. Understand each change.'
                : 'Gặp làn da. Hiểu từng thay đổi.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loading) const LinearProgressIndicator(),
                if (_failed)
                  HealthCard(
                    child: Column(
                      children: [
                        Text(
                          en
                              ? 'Could not load saved results.'
                              : 'Chưa tải được kết quả đã lưu.',
                        ),
                        TextButton(
                          onPressed: _load,
                          child: Text(en ? 'Retry' : 'Thử lại'),
                        ),
                      ],
                    ),
                  ),
                if (!_loading && !_failed)
                  ScanTrendCard(
                    scans: _scans,
                    isEnglish: en,
                    onOpenHistory: _history,
                  ),
                const SizedBox(height: 20),
                HealthCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(70),
                          color: colors.primary.withValues(alpha: .10),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: .30),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.document_scanner_outlined,
                          size: 36,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        en
                            ? 'AI scanning under maintenance'
                            : 'Quét AI đang bảo trì',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        en
                            ? 'Use even lighting and keep the camera at eye level.'
                            : 'Chọn nơi đủ sáng và giữ camera ngang tầm mắt.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.camera_alt_outlined, size: 20),
                          label: Text(
                            en
                                ? 'Scanning under maintenance'
                                : 'Quét da đang bảo trì',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        en
                            ? 'AI scanning is being completed and tested. You can still view your saved results.'
                            : 'Quét AI đang được hoàn thiện và kiểm thử. Bạn vẫn có thể xem các kết quả đã lưu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  en ? 'Your scans' : 'Các lần quét của bạn',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                HealthCard(
                  onTap: _history,
                  child: Row(
                    children: [
                      Icon(Icons.history, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          en ? 'View saved results' : 'Xem kết quả đã lưu',
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
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

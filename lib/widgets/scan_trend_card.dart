import 'package:flutter/material.dart';
import '../screens/home/scan_history.dart';

class ScanTrendCard extends StatefulWidget {
  const ScanTrendCard({
    super.key,
    required this.scans,
    required this.isEnglish,
    required this.onOpenHistory,
  });
  final List<SavedScan> scans;
  final bool isEnglish;
  final VoidCallback onOpenHistory;
  @override
  State<ScanTrendCard> createState() => _ScanTrendCardState();
}

class _ScanTrendCardState extends State<ScanTrendCard> {
  String? selectedId;
  @override
  Widget build(BuildContext context) {
    final en = widget.isEnglish;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? const Color(0xFFB8B5FF) : const Color(0xFF6264D9);
    final scans = widget.scans.take(7).toList().reversed.toList();
    final selected =
        scans.where((s) => s.id == selectedId).firstOrNull ?? scans.lastOrNull;
    final maximum = scans.fold<int>(
      1,
      (value, scan) => scan.acneCount > value ? scan.acneCount : value,
    );
    return Material(
      color: dark ? const Color(0xFF20212B) : Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    en ? 'Your skin over time' : 'Làn da theo thời gian',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: en ? 'Scan history' : 'Lịch sử soi da',
                  onPressed: widget.onOpenHistory,
                  icon: const Icon(Icons.chevron_right, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (selected == null) ...[
              Text(
                en ? 'Start tracking your skin' : 'Bắt đầu theo dõi làn da',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                en
                    ? 'Saved scans will appear here. AI scanning is being completed.'
                    : 'Các lần quét đã lưu sẽ xuất hiện tại đây. Quét AI đang được hoàn thiện.',
                style: TextStyle(
                  color: dark ? Colors.white60 : const Color(0xFF898992),
                  height: 1.5,
                ),
              ),
            ] else ...[
              Text(
                '${selected.acneCount}',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                en
                    ? 'spots detected · ${selected.createdAt.day}/${selected.createdAt.month}'
                    : 'nốt được phát hiện · ${selected.createdAt.day}/${selected.createdAt.month}',
                style: TextStyle(
                  color: dark ? Colors.white60 : const Color(0xFF898992),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: scans
                      .map(
                        (scan) => Expanded(
                          child: Semantics(
                            button: true,
                            selected: selected.id == scan.id,
                            label:
                                '${scan.createdAt.day}/${scan.createdAt.month}: ${scan.acneCount}',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() => selectedId = scan.id),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${scan.acneCount}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    width: 24,
                                    height: scan.acneCount == 0
                                        ? 2
                                        : 90 * scan.acneCount / maximum,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: selected.id == scan.id
                                          ? accent
                                          : accent.withValues(alpha: .22),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${scan.createdAt.day}/${scan.createdAt.month}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                en
                    ? 'Detected spots, not a skin health score.'
                    : 'Số nốt phát hiện, không phải điểm sức khỏe da.',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

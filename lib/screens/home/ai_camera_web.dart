import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_provider.dart';

/// Web can show the app; local TFLite inference runs in the separate tester.
class AiCameraTab extends StatelessWidget {
  const AiCameraTab({super.key});

  @override
  Widget build(BuildContext context) {
    final en = context.watch<AppProvider>().isEnglish;
    final url = Uri.parse('http://127.0.0.1:8765');
    return Scaffold(
      appBar: AppBar(title: Text(en ? 'AI skin scan' : 'Quét da AI')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.computer_outlined, size: 64),
          const SizedBox(height: 24),
          Text(
            en ? 'Test AI in your browser' : 'Thử AI trên trình duyệt',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            en
                ? 'The browser app does not run the native TFLite engine. On this Mac, open the local tester to choose photos and run both real models.'
                : 'Bản web không chạy bộ TFLite của điện thoại. Trên Mac này, bạn có thể mở trang thử cục bộ để chọn ảnh và chạy cả hai model thật.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(en ? 'Open local AI tester' : 'Mở trang thử AI cục bộ'),
            onPressed: () async {
              try {
                final opened = await launchUrl(
                  url,
                  webOnlyWindowName: '_blank',
                );
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        en
                            ? 'Open http://127.0.0.1:8765 in a new tab.'
                            : 'Mở http://127.0.0.1:8765 trong tab mới.',
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      en
                          ? 'Could not open the tester. Open http://127.0.0.1:8765 manually.'
                          : 'Chưa mở được trang thử. Mở http://127.0.0.1:8765 bằng tab mới.',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            en
                ? 'If the page is unavailable, run Start AI Browser.command from the project folder. Test history stays in that tab and does not sync with the app.'
                : 'Nếu trang chưa mở được, chạy file Start AI Browser.command trong thư mục dự án. Lịch sử thử chỉ nằm trong tab đó và không đồng bộ với app.',
          ),
        ],
      ),
    );
  }
}

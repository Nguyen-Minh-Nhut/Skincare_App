import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _accent = Color(0xFF6264D9);
const _ink = Color(0xFF252630);
const _muted = Color(0xFF898992);
const _green = Color(0xFF5688C7);

class MeowSkinPreview extends StatelessWidget {
  const MeowSkinPreview({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MeowSkin · Design Preview',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: const Color(0xFFF3F3F7),
      colorScheme: ColorScheme.fromSeed(seedColor: _accent),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: _ink)),
    ),
    home: const _PreviewHome(),
  );
}

class _PreviewHome extends StatefulWidget {
  const _PreviewHome();
  @override
  State<_PreviewHome> createState() => _PreviewHomeState();
}

class _PreviewHomeState extends State<_PreviewHome> {
  int tab = 0;
  bool evening = false;
  int selectedScan = 4;
  bool scanComplete = false;
  final likedPosts = <int>{};
  static const scanScores = [62, 68, 65, 74, 82];
  static const scanDates = ['02/10', '05/10', '09/10', '13/10', '16/10'];
  final completed = <int>{0, 1};

  void detail(String title, String description) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(fontSize: 17, height: 1.6, color: _muted),
            ),
            const SizedBox(height: 20),
            const Text(
              'BẢN THỬ GIAO DIỆN · DỮ LIỆU MINH HỌA',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.3,
                color: _accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 430,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDFE9FC),
                    Color(0xFFE8E3FA),
                    Color(0xFFF3F3F7),
                  ],
                  stops: [0, .46, 1],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                key: ValueKey(tab),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
                children: [
                  Row(
                    children: [
                      const Icon(
                        PhosphorIconsFill.cat,
                        color: _accent,
                        size: 23,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'meowskin',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.7,
                        ),
                      ),
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'BẢN XEM THỬ',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.2,
                                color: _muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => detail(
                          'Xin chào, Nhựt',
                          'Đây là không gian chăm sóc da của bạn. Hồ sơ và các chỉ số trong bản thử này là dữ liệu minh họa.',
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .65),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white),
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.user,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 33),
                  const Text(
                    'THỨ SÁU, 16 THÁNG 10',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    [
                      'Làn da của bạn',
                      'Chăm sóc',
                      'Quét da AI',
                      'Cộng đồng',
                      'Khám phá',
                    ][tab],
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.6,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    [
                      'Một chút chăm sóc, mỗi ngày.',
                      'Thói quen nhỏ. Thay đổi dài lâu.',
                      'Gặp làn da. Hiểu từng thay đổi.',
                      'Cùng chia sẻ, cùng chăm da.',
                      'Hiểu làn da, thương mình hơn.',
                    ][tab],
                    style: const TextStyle(fontSize: 15, color: _muted),
                  ),
                  const SizedBox(height: 29),
                  if (tab == 0) ..._summary(),
                  if (tab == 1) ..._care(),
                  if (tab == 2) ..._scan(),
                  if (tab == 3) ..._community(),
                  if (tab == 4) ..._discover(),
                  const SizedBox(height: 26),
                  const Center(
                    child: Text(
                      'Dành một chút dịu dàng cho làn da bạn.',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Icon(
                      PhosphorIconsRegular.cat,
                      size: 18,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 22,
          left: 24,
          right: 24,
          child: SafeArea(
            top: false,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: List.generate(
                        5,
                        (index) => Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: () => setState(() => tab = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: tab == index
                                    ? const Color(0xFFEAE9FC)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    [
                                      PhosphorIconsFill.heart,
                                      PhosphorIconsRegular.sunHorizon,
                                      PhosphorIconsRegular.scan,
                                      PhosphorIconsRegular.users,
                                      PhosphorIconsRegular.squaresFour,
                                    ][index],
                                    color: tab == index ? _accent : _ink,
                                    size: 25,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      'Tóm tắt',
                                      'Chăm sóc',
                                      'Quét AI',
                                      'Cộng đồng',
                                      'Khám phá',
                                    ][index],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: tab == index ? _accent : _ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget section(String title, {String? action}) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 13),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: () => detail(
              title,
              'Bạn sẽ có thể tùy chỉnh những thông tin xuất hiện ở đây. Đây là bản xem thử bố cục.',
            ),
            child: Text(
              action,
              style: const TextStyle(color: _accent, fontSize: 14),
            ),
          ),
      ],
    ),
  );

  Widget card({required Widget child, VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(21), child: child),
      ),
    ),
  );

  Widget label(IconData icon, String title, Color color, {String? trailing}) =>
      Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null)
            Text(trailing, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Color(0xFFCDCDD2), size: 19),
        ],
      );

  List<Widget> _summary() => [
    section('Tổng quan', action: 'Tùy chỉnh'),
    _scoreCard(),
    card(
      onTap: () => detail(
        'Nhật ký làn da',
        'Ghi lại cảm nhận và ảnh theo thời gian để hiểu làn da của mình hơn. Nhận xét ở đây chỉ là nội dung mẫu; chưa có phân tích AI được thực hiện.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label(
            PhosphorIconsRegular.flowerLotus,
            'Nhật ký làn da',
            _green,
            trailing: 'Hôm nay',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Một ngày khá dịu êm',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.7,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Da dễ chịu · Không căng rát',
                      style: TextStyle(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFCCD6F5), Color(0xFFF1F3FC)],
                  ),
                ),
                child: const Icon(
                  PhosphorIconsRegular.flowerLotus,
                  color: _green,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    card(
      onTap: () => setState(() => tab = 2),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDFC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              PhosphorIconsRegular.scan,
              color: _accent,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quét da cùng AI',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5),
                Text(
                  'Theo dõi điểm da qua từng lần quét',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.add_circle, color: _accent, size: 28),
        ],
      ),
    ),
    const SizedBox(height: 15),
    ..._care(),
    const SizedBox(height: 15),
    section('Một chút kiến thức'),
    _article(),
  ];

  Widget _scoreCard() => card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label(
          PhosphorIconsRegular.scan,
          'Điểm làn da',
          _accent,
          trailing: 'Tháng 10',
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${scanScores[selectedScan]}',
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        ' / 100',
                        style: TextStyle(fontSize: 17, color: _muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedScan == 4 ? '↑ 8 điểm' : 'Lần ${selectedScan + 1}',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'Lần quét ${scanDates[selectedScan]} · ${selectedScan == 4 ? 'Đang cải thiện' : 'Đã lưu kết quả'}',
          style: const TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 150,
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 12, bottom: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('100', style: TextStyle(fontSize: 10, color: _muted)),
                    Text('50', style: TextStyle(fontSize: 10, color: _muted)),
                    Text('0', style: TextStyle(fontSize: 10, color: _muted)),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      bottom: 24,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          3,
                          (_) => Container(
                            height: 1,
                            color: const Color(0xFFF0F0F6),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        scanScores.length,
                        (i) => Expanded(
                          child: Semantics(
                            button: true,
                            selected: selectedScan == i,
                            label:
                                'Lần quét ${scanDates[i]}, ${scanScores[i]} trên 100 điểm',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(() => selectedScan = i),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${scanScores[i]}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: selectedScan == i
                                          ? _accent
                                          : _muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 26,
                                    height: scanScores[i] * 1.14,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: selectedScan == i
                                            ? [
                                                const Color(0xFF6264D9),
                                                const Color(0xFF8B9CF2),
                                              ]
                                            : [
                                                const Color(0xFFDADBF7),
                                                const Color(0xFFE5E9FC),
                                              ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    scanDates[i],
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '5 lần quét · Chạm vào cột để xem điểm',
          style: TextStyle(fontSize: 11, color: _muted),
        ),
        const SizedBox(height: 5),
        const Text(
          'Điểm minh họa giao diện, chưa phải kết quả AI.',
          style: TextStyle(fontSize: 10, color: _muted),
        ),
      ],
    ),
  );

  List<Widget> _scan() => [
    card(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 168,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(70),
              gradient: const LinearGradient(
                colors: [Color(0xFFE5EDFF), Color(0xFFEAE3FC)],
              ),
              border: Border.all(color: const Color(0xFFBBBFF0), width: 2),
            ),
            child: const Icon(
              PhosphorIconsRegular.scan,
              size: 76,
              color: _accent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Một tấm ảnh, một lần hiểu da',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Đặt mặt trong khung, chọn nơi đủ sáng và giữ camera ngang tầm mắt.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.all(17),
              ),
              onPressed: () => setState(() => scanComplete = true),
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              label: const Text('Thử kết quả mẫu'),
            ),
          ),
          TextButton.icon(
            onPressed: () => detail(
              'Chọn ảnh',
              'Bản demo minh họa bước chọn ảnh. Camera, thư viện và mô hình AI sẽ được kết nối khi tích hợp vào app.',
            ),
            icon: const Icon(Icons.photo_outlined, size: 18),
            label: const Text('Chọn ảnh từ thư viện'),
          ),
          const Text(
            'Bản thử giao diện · Chưa sử dụng camera hoặc AI',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
    ),
    if (scanComplete) ...[
      section('Kết quả minh họa'),
      _scoreCard(),
      card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label(PhosphorIconsRegular.flowerLotus, 'Gợi ý chăm sóc', _accent),
            const SizedBox(height: 14),
            const Text(
              'Duy trì routine dịu nhẹ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đây là nội dung mẫu để xem bố cục kết quả, chưa được suy ra từ ảnh của bạn.',
              style: TextStyle(color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    ],
    section('Các lần quét gần đây'),
    ...List.generate(
      3,
      (i) => card(
        onTap: () => setState(() {
          selectedScan = 4 - i;
          scanComplete = true;
        }),
        child: label(
          PhosphorIconsRegular.scan,
          '${scanDates[4 - i]} · ${scanScores[4 - i]}/100 điểm',
          _accent,
        ),
      ),
    ),
  ];

  List<Widget> _community() => [
    card(
      onTap: () => detail(
        'Chia sẻ một chút',
        'Đây là bản thử trình soạn bài. Bài viết chưa được đăng lên cộng đồng thật.',
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFEEEDFC),
            child: Icon(Icons.person_outline, color: _accent),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hôm nay da bạn thế nào?',
              style: TextStyle(color: _muted),
            ),
          ),
          Icon(Icons.add_circle, color: _accent),
        ],
      ),
    ),
    section('Cùng nhau chăm da', action: 'Dành cho bạn'),
    ...List.generate(
      3,
      (i) => card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEAE9FC),
                  child: Text(
                    ['L', 'M', 'A'][i],
                    style: const TextStyle(color: _accent),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ['Linh Nguyễn', 'Minh Anh', 'An Nhiên'][i],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        'Bài viết minh họa · 2 giờ trước',
                        style: TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: _muted),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              [
                'Routine ít bước, đều đặn hơn',
                'Một chút tiến bộ mỗi tuần',
                'Góc tủ đồ tối giản',
              ][i],
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              [
                'Mình đang học cách kiên nhẫn với làn da. Còn bạn, bước nào trong routine khiến bạn thấy dễ chịu nhất?',
                'Lưu lại từng lần quét giúp mình nhìn rõ thay đổi hơn. Chăm da là cả một hành trình.',
                'Giữ lại những món phù hợp và dành thêm thời gian lắng nghe da mình.',
              ][i],
              style: const TextStyle(fontSize: 14, color: _muted, height: 1.6),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() {
                    likedPosts.contains(i)
                        ? likedPosts.remove(i)
                        : likedPosts.add(i);
                  }),
                  icon: Icon(
                    likedPosts.contains(i)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 19,
                  ),
                  label: Text(
                    '${[24, 18, 32][i] + (likedPosts.contains(i) ? 1 : 0)}',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => detail(
                    'Trò chuyện cùng nhau',
                    'Phần bình luận đang được minh họa trong bản demo. Chưa tải hoặc lưu bình luận thật.',
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Bình luận'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ];

  List<Widget> _care() => [
    section('Dành cho hôm nay'),
    card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label(
            PhosphorIconsRegular.sunHorizon,
            'Thói quen của bạn',
            const Color(0xFFD39A49),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: List.generate(
                2,
                (i) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      evening = i == 1;
                      completed.clear();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: evening == (i == 1)
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          ['Buổi sáng', 'Buổi tối'][i],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (i) => InkWell(
              onTap: () => setState(
                () => completed.contains(i)
                    ? completed.remove(i)
                    : completed.add(i),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: [
                    Icon(
                      completed.contains(i)
                          ? PhosphorIconsFill.checkCircle
                          : PhosphorIconsRegular.circle,
                      color: completed.contains(i)
                          ? _green
                          : const Color(0xFFD3D3DA),
                      size: 25,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (evening
                            ? [
                                'Làm sạch dịu nhẹ',
                                'Dưỡng ẩm',
                                'Ghi lại cảm nhận',
                              ]
                            : [
                                'Làm sạch dịu nhẹ',
                                'Dưỡng ẩm',
                                'Chống nắng',
                              ])[i],
                        style: TextStyle(
                          fontSize: 15,
                          color: completed.contains(i) ? _muted : _ink,
                        ),
                      ),
                    ),
                    Text(
                      '0${i + 1}',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(color: Color(0xFFF0F0F4)),
          const SizedBox(height: 8),
          Text(
            '${completed.length} / 3 bước hoàn thành',
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ],
      ),
    ),
  ];

  Widget _article() => card(
    onTap: () => detail(
      'Chậm lại một chút',
      'Một routine đơn giản và phù hợp dễ duy trì hơn việc thay nhiều sản phẩm cùng lúc. Đây là nội dung minh họa cho giao diện bài viết.',
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(PhosphorIconsRegular.cat, color: _accent, size: 27),
            const SizedBox(width: 8),
            const Text(
              'GÓC NHỎ MEOW',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: _accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Text(
              '3 phút đọc',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Da cũng cần\nmột nhịp nghỉ.',
          style: TextStyle(
            fontSize: 29,
            height: 1.12,
            letterSpacing: -.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Chăm ít hơn, nhưng hiểu da nhiều hơn.',
          style: TextStyle(fontSize: 13, color: _muted),
        ),
      ],
    ),
  );

  List<Widget> _discover() => [
    section('Góc nhỏ Meow'),
    _article(),
    card(
      onTap: () => detail(
        'Tủ đồ chăm da',
        'Không gian dự kiến để xem sản phẩm đang dùng và sắp xếp routine. Bản xem thử chưa đọc hay lưu sản phẩm thật.',
      ),
      child: label(PhosphorIconsRegular.squaresFour, 'Tủ đồ chăm da', _green),
    ),
    card(
      onTap: () => detail(
        'Cùng nhau chăm da',
        'Góc cộng đồng sẽ xuất hiện ở đây. Bản thử không đăng bài hay tải dữ liệu người dùng.',
      ),
      child: label(PhosphorIconsRegular.users, 'Cùng nhau chăm da', _accent),
    ),
  ];
}

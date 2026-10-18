import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _rose = Color(0xFFDD6479);
const _ink = Color(0xFF252630);
const _muted = Color(0xFF898992);
const _green = Color(0xFF52A58F);

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
      colorScheme: ColorScheme.fromSeed(seedColor: _rose),
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
              style: TextStyle(fontSize: 10, letterSpacing: 1.3, color: _rose),
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
                    Color(0xFFF7DADC),
                    Color(0xFFE8E5F5),
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
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
                children: [
                  Row(
                    children: [
                      const Icon(PhosphorIconsFill.cat, color: _rose, size: 23),
                      const SizedBox(width: 8),
                      const Text(
                        'meowskin',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.7,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'BẢN XEM THỬ',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: _muted,
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
                    ['Làn da của bạn', 'Chăm sóc', 'Khám phá'][tab],
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
                      'Hiểu làn da, thương mình hơn.',
                    ][tab],
                    style: const TextStyle(fontSize: 15, color: _muted),
                  ),
                  const SizedBox(height: 29),
                  if (tab == 0) ..._summary(),
                  if (tab == 1) ..._care(),
                  if (tab == 2) ..._discover(),
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
                      color: _rose,
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
                    constraints: const BoxConstraints(maxWidth: 370),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: () => setState(() => tab = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: tab == index
                                    ? const Color(0xFFF8E8EB)
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
                                      PhosphorIconsRegular.squaresFour,
                                    ][index],
                                    color: tab == index ? _rose : _ink,
                                    size: 25,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ['Tóm tắt', 'Chăm sóc', 'Khám phá'][index],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: tab == index ? _rose : _ink,
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
          ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: () => detail(
              title,
              'Bạn sẽ có thể tùy chỉnh những thông tin xuất hiện ở đây. Đây là bản xem thử bố cục.',
            ),
            child: Text(
              action,
              style: const TextStyle(color: _rose, fontSize: 14),
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
    card(
      onTap: () => detail(
        'Nhịp chăm sóc của bạn',
        'Bạn đã chăm sóc da 5 trong 7 ngày ở tuần minh họa này. Biểu đồ phản ánh thói quen, không phải điểm sức khỏe hay chẩn đoán da.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label(
            PhosphorIconsFill.heart,
            'Nhịp chăm sóc',
            _rose,
            trailing: 'Tuần này',
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '5',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              letterSpacing: -2,
                            ),
                          ),
                          TextSpan(
                            text: ' / 7 ngày',
                            style: TextStyle(fontSize: 15, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Đều đặn hơn tuần trước',
                      style: TextStyle(fontSize: 12, color: _green),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  7,
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Column(
                      children: [
                        Container(
                          width: 13,
                          height: [30.0, 51.0, 42.0, 65.0, 57.0, 16.0, 16.0][i],
                          decoration: BoxDecoration(
                            color: i == 4
                                ? _rose
                                : i < 4
                                ? const Color(0xFFF0CCD3)
                                : const Color(0xFFF0F0F4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][i],
                          style: const TextStyle(fontSize: 8, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
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
                    colors: [Color(0xFFB0DACE), Color(0xFFF1F8F5)],
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
      onTap: () => detail(
        'Lưu một khoảnh khắc',
        'Luồng dự kiến: chụp hoặc chọn ảnh, kiểm tra ánh sáng rồi lưu nhật ký. Bản xem thử không mở camera hay chạy mô hình AI.',
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFBECEF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              PhosphorIconsRegular.scan,
              color: _rose,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gặp làn da hôm nay',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5),
                Text(
                  'Thêm ảnh vào nhật ký của bạn',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.add_circle, color: _rose, size: 28),
        ],
      ),
    ),
    const SizedBox(height: 15),
    ..._care(),
    const SizedBox(height: 15),
    section('Một chút kiến thức'),
    _article(),
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
            const Icon(PhosphorIconsRegular.cat, color: _rose, size: 27),
            const SizedBox(width: 8),
            const Text(
              'GÓC NHỎ MEOW',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: _rose,
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
      child: label(PhosphorIconsRegular.users, 'Cùng nhau chăm da', _rose),
    ),
  ];
}

import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../app_provider.dart';
import '../../services/scan_input_check.dart';
import '../profile/scan_history_screen.dart';
import 'acne_detector.dart';
import 'scan_history.dart';

/// Experimental native scan flow. Browser model testing has a local runner.
class AiCameraTab extends StatefulWidget {
  const AiCameraTab({super.key});
  @override
  State<AiCameraTab> createState() => _AiCameraTabState();
}

class _AiCameraTabState extends State<AiCameraTab> {
  AcneDetectorPipeline? _detector;
  Uint8List? _bytes;
  Size? _size;
  List<AcneBox>? _boxes;
  bool _loading = true, _scanning = false, _saving = false, _saved = false;
  bool _preparing = false, _validated = false;
  String? _error;
  bool get _en => context.read<AppProvider>().isEnglish;
  String t(String vi, String en) => _en ? en : vi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detector = await AcneDetectorPipeline.create();
      if (!mounted) {
        await detector.dispose();
        return;
      }
      _detector = detector;
    } catch (error) {
      if (kDebugMode) debugPrint('Scan model initialization failed: $error');
      if (mounted) {
        _error = t(
          'Chưa tải được model. Hãy thử lại.',
          'Could not load the models. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_scanning || _saving || _preparing) return;
    setState(() => _preparing = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      if (file == null || !mounted) return;
      if (await file.length() > 12 * 1024 * 1024) {
        throw const FormatException('image-too-large');
      }
      final decoded = img.decodeImage(await file.readAsBytes());
      if (decoded == null || decoded.width < 224 || decoded.height < 224) {
        throw const FormatException('invalid-image');
      }
      await _acceptImage(img.bakeOrientation(decoded));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = t(
            'Chưa mở được ảnh. Kiểm tra quyền camera/thư viện và chọn ảnh rõ nét, ít nhất 224 pixel mỗi chiều, dưới 12 MB.',
            'Could not open the image. Check camera/photo permissions and select a clear image, at least 224 pixels on each side and below 12 MB.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  String _issueText(String issue) => switch (issue) {
    'no-face' => t(
      'Chưa tìm thấy khuôn mặt. Chọn ảnh có đủ mắt, mũi, miệng; ảnh cận da quá sát chưa được hỗ trợ.',
      'No face found. Include your eyes, nose and mouth; tight skin crops are not supported.',
    ),
    'multiple-faces' => t(
      'Ảnh có nhiều khuôn mặt. Chọn ảnh chỉ có một người, không ghép ảnh.',
      'Multiple faces found. Use one person, not a collage.',
    ),
    'face-angle' => t(
      'Mặt đang nghiêng hoặc ảnh bị xoay. Dùng nút xoay ảnh hoặc chụp thẳng hơn.',
      'The face is tilted or rotated. Rotate the photo or face the camera more directly.',
    ),
    'face-small' => t(
      'Khuôn mặt quá xa. Chụp gần hơn, giữ cả khuôn mặt trong ảnh.',
      'Your face is too small. Move closer while keeping the whole face visible.',
    ),
    'lighting' => t(
      'Ảnh quá tối hoặc quá sáng. Chọn nơi có ánh sáng đều và chụp lại.',
      'The photo is too dark or bright. Retake it with even lighting.',
    ),
    _ => t(
      'Chưa kiểm tra được khuôn mặt. Hãy thử lại hoặc chọn ảnh khác.',
      'Could not validate the face. Retry or choose another photo.',
    ),
  };

  Future<void> _acceptImage(img.Image oriented) async {
    final bytes = Uint8List.fromList(img.encodeJpg(oriented, quality: 95));
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _size = Size(oriented.width.toDouble(), oriented.height.toDouble());
      _boxes = null;
      _saved = false;
      _validated = false;
      _error = null;
    });
    var luminance = 0.0, samples = 0;
    for (var y = 0; y < oriented.height; y += 16) {
      for (var x = 0; x < oriented.width; x += 16) {
        final pixel = oriented.getPixel(x, y);
        luminance += .299 * pixel.r + .587 * pixel.g + .114 * pixel.b;
        samples++;
      }
    }
    String? issue;
    try {
      issue = luminance / samples < 25 || luminance / samples > 240
          ? 'lighting'
          : await ScanInputCheck()
                .validate(bytes)
                .timeout(const Duration(seconds: 20));
    } catch (_) {
      issue = 'check-failed';
    }
    if (mounted) {
      setState(() {
        _validated = issue == null;
        _error = issue == null ? null : _issueText(issue);
      });
    }
  }

  Future<void> _rotate() async {
    if (_bytes == null || _preparing || _scanning || _saving) return;
    setState(() => _preparing = true);
    try {
      await _acceptImage(img.copyRotate(img.decodeImage(_bytes!)!, angle: 90));
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _analyze() async {
    if (_bytes == null ||
        _detector == null ||
        _scanning ||
        !_validated ||
        _preparing) {
      return;
    }
    setState(() {
      _scanning = true;
      _error = null;
      _boxes = null;
      _saved = false;
    });
    try {
      final boxes = await _detector!.detectAndFilter(_bytes!);
      if (mounted) setState(() => _boxes = boxes);
    } catch (error) {
      if (kDebugMode) debugPrint('Scan inference failed: $error');
      await _detector?.dispose();
      _detector = null;
      if (mounted) {
        setState(
          () => _error = t(
            'Phân tích thất bại. Tải lại model hoặc chọn ảnh khác để thử lại.',
            'Analysis failed. Reload the models or choose another photo.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      } else {
        await _detector?.dispose();
      }
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_saving || _saved || _bytes == null || _boxes == null) return;
    if (uid == null) {
      setState(
        () =>
            _error = t('Đăng nhập để lưu kết quả.', 'Sign in to save results.'),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    File? temporary;
    try {
      final dir = await getTemporaryDirectory();
      temporary = File(
        '${dir.path}/scan_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await temporary.writeAsBytes(_bytes!);
      await ScanHistoryStore.save(
        userId: uid,
        sourceImage: temporary,
        imageWidth: _size!.width.toInt(),
        imageHeight: _size!.height.toInt(),
        regions: _boxes!
            .map(
              (box) => <String, double>{
                'left': box.left,
                'top': box.top,
                'width': box.width,
                'height': box.height,
                'confidence': box.confidence,
              },
            )
            .toList(),
        acneCount: _boxes!.length,
        level: t(
          'Kết quả thử nghiệm · vùng nghi ngờ',
          'Experimental result · suspected spots',
        ),
        morningRoutine: '',
        nightRoutine: '',
        activeIngredients: '',
        warning: t(
          'Không phải chẩn đoán. Không suy ra mức độ bệnh hoặc chọn thuốc từ số vùng phát hiện. Nhận diện mụn đầu đen còn hạn chế; có thể bỏ sót hoặc nhận nhầm.',
          'Not a diagnosis. Do not infer severity or choose medication from the spot count. Blackhead detection is limited; spots may be missed or falsely detected.',
        ),
      );
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = t(
            'Chưa lưu được kết quả. Vui lòng thử lại.',
            'Could not save results. Please retry.',
          ),
        );
      }
    } finally {
      try {
        if (temporary != null && await temporary.exists()) {
          await temporary.delete();
        }
      } catch (_) {
        /* Temporary file cleanup must not change save status. */
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    // Keep the interpreter alive until any current inference completes.
    if (!_scanning) unawaited(_detector?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    final colors = Theme.of(context).colorScheme;
    final busy = _scanning || _saving || _preparing;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            t('Quét da AI · Thử nghiệm', 'AI skin scan · Experimental'),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              t(
                'Chọn ảnh → Phân tích → Lưu kết quả',
                'Choose a photo → Analyze → Save',
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              t(
                'Ảnh rõ mặt, đủ sáng, không có bộ lọc. Đặt mặt ở giữa ảnh. Ảnh được phân tích trên thiết bị.',
                'Use a clear, evenly lit photo without filters. Center your face. Images are analyzed on this device.',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t(
                'Kết quả chỉ là vùng nghi ngờ, không phải chẩn đoán. Nhận diện mụn đầu đen còn hạn chế. Chỉ dùng ảnh một người, đủ mặt, không ghép ảnh.',
                'Results are suspected spots, not a diagnosis. Blackhead detection is limited. Use a single, complete face without collages.',
              ),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (_preparing) ...[
              const LinearProgressIndicator(),
              Text(
                t(
                  'Đang kiểm tra ảnh và khuôn mặt…',
                  'Checking image and face…',
                ),
              ),
            ],
            if (_validated && !_preparing)
              Text(
                t(
                  'Ảnh đủ điều kiện để quét thử nghiệm.',
                  'Photo ready for experimental scanning.',
                ),
              ),
            if (_loading) ...[
              const LinearProgressIndicator(),
              Text(t('Đang tải hai model…', 'Loading both models…')),
            ],
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: colors.error)),
              if (_detector == null && !_loading)
                TextButton(
                  onPressed: _load,
                  child: Text(t('Tải lại model', 'Reload models')),
                ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _detector == null || busy
                      ? null
                      : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(t('Chụp ảnh', 'Camera')),
                ),
                OutlinedButton.icon(
                  onPressed: _detector == null || busy
                      ? null
                      : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(t('Chọn ảnh', 'Choose photo')),
                ),
              ],
            ),
            if (_bytes != null && _size != null) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: _size!.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(_bytes!, fit: BoxFit.contain),
                      if (_boxes != null)
                        CustomPaint(
                          painter: AcneBoundingBoxPainter(
                            boxes: _boxes!,
                            imageSize: _size!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy || !_validated || _detector == null
                    ? null
                    : _analyze,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(
                  _scanning
                      ? t('Đang phân tích…', 'Analyzing…')
                      : t('Phân tích ảnh', 'Analyze photo'),
                ),
              ),
            ],
            if (_bytes != null)
              TextButton.icon(
                onPressed: busy ? null : _rotate,
                icon: const Icon(Icons.rotate_right),
                label: Text(t('Xoay ảnh 90°', 'Rotate photo 90°')),
              ),
            if (_scanning)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            if (_boxes != null) ...[
              const SizedBox(height: 20),
              Text(
                t(
                  '${_boxes!.length} vùng nghi ngờ được phát hiện',
                  '${_boxes!.length} suspected spots detected',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_boxes!.isEmpty)
                Text(
                  t(
                    'Không có vùng được model giữ lại. Điều này không xác nhận da không có mụn.',
                    'The model retained no spots. This does not confirm acne-free skin.',
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy || _saved ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _saved
                      ? t('Đã lưu', 'Saved')
                      : _saving
                      ? t('Đang lưu…', 'Saving…')
                      : t('Lưu kết quả', 'Save results'),
                ),
              ),
              if (_saved)
                Text(
                  t(
                    'Đã lưu ảnh và khung nhận diện vào lịch sử trên thiết bị này.',
                    'Photo and detected regions saved to history on this device.',
                  ),
                ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanHistoryScreen(),
                        ),
                      ),
                child: Text(t('Xem lịch sử', 'View history')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AcneBoundingBoxPainter extends CustomPainter {
  const AcneBoundingBoxPainter({required this.boxes, required this.imageSize});
  final List<AcneBox> boxes;
  final Size imageSize;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final scale = size.width / imageSize.width;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final box in boxes) {
      canvas.drawRect(
        Rect.fromLTWH(
          box.left * scale,
          box.top * scale,
          box.width * scale,
          box.height * scale,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AcneBoundingBoxPainter oldDelegate) =>
      oldDelegate.boxes != boxes || oldDelegate.imageSize != imageSize;
}

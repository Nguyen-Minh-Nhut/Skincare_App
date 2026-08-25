import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

// Import file wrapper AI (chứa AcneDetectorPipeline)
import 'acne_detector.dart';
import 'scan_history.dart';

class AiCameraTab extends StatefulWidget {
  const AiCameraTab({super.key});

  @override
  State<AiCameraTab> createState() => _AiCameraTabState();
}

class _AiCameraTabState extends State<AiCameraTab>
    with SingleTickerProviderStateMixin {
  File? _imageFile;
  bool _isScanning = false;
  bool _showResult = false;
  bool _isModelReady = false;
  String? _modelError;

  Size? _imageSize;
  List<AcneBox> _detectedBoxes = [];

  // 1. CHUYỂN SANG DÙNG PIPELINE MỚI CÓ CẢ YOLO VÀ CNN
  AcneDetectorPipeline? _detector;
  int _analysisGeneration = 0;

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initAI();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _scanController.reverse();
          } else if (status == AnimationStatus.dismissed) {
            _scanController.forward();
          }
        });
  }

  Future<void> _initAI() async {
    if (mounted) {
      setState(() {
        _isModelReady = false;
        _modelError = null;
      });
    }
    try {
      // 2. GỌI HÀM KHỞI TẠO CỦA PIPELINE
      _detector = await AcneDetectorPipeline.create();
      if (!mounted) return;
      setState(() => _isModelReady = true);
      debugPrint("✅ Đã load xong cả model YOLO và CNN!");
    } catch (e) {
      debugPrint("❌ Lỗi load model AI: $e");
      if (!mounted) return;
      setState(() => _modelError = 'Không thể tải model AI. Vui lòng thử lại.');
    }
  }

  @override
  void dispose() {
    _analysisGeneration++;
    final detector = _detector;
    _detector = null;
    if (detector != null) unawaited(detector.dispose());
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (image != null) {
      if (!mounted) return;
      final generation = ++_analysisGeneration;
      setState(() {
        _imageFile = File(image.path);
        _isScanning = true;
        _showResult = false;
        _detectedBoxes.clear();
      });

      _scanController.forward();

      try {
        final bytes = await File(image.path).readAsBytes();

        final completer = Completer<ui.Image>();
        final imageStream = FileImage(
          File(image.path),
        ).resolve(const ImageConfiguration());
        late final ImageStreamListener listener;
        listener = ImageStreamListener(
          (ImageInfo info, bool _) {
            if (!completer.isCompleted) completer.complete(info.image);
            imageStream.removeListener(listener);
          },
          onError: (Object error, StackTrace? stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
            imageStream.removeListener(listener);
          },
        );
        imageStream.addListener(listener);
        final uiImage = await completer.future;
        if (!mounted || generation != _analysisGeneration) return;
        _imageSize = Size(uiImage.width.toDouble(), uiImage.height.toDouble());

        if (_detector != null) {
          // 3. SỬ DỤNG HÀM detectAndFilter ĐỂ CHẠY BỘ LỌC KÉP
          final boxes = await _detector!.detectAndFilter(
            bytes,
            minConfidence: 0.08,
            trustedDetectorConfidence: 0.15,
          );

          if (mounted && generation == _analysisGeneration) {
            setState(() {
              _detectedBoxes = boxes;
              _isScanning = false;
              _showResult = true;
            });
            _scanController.stop();
          }
        } else {
          throw Exception("Model chưa được load xong!");
        }
      } catch (e) {
        if (!mounted || generation != _analysisGeneration) return;
        debugPrint("Lỗi phân tích AI: $e");
        if (mounted) {
          setState(() => _isScanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không thể phân tích ảnh này. Vui lòng thử ảnh khác.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _resetCamera() {
    _analysisGeneration++;
    _scanController.stop();
    setState(() {
      _imageFile = null;
      _isScanning = false;
      _showResult = false;
      _detectedBoxes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Phân tích da AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_imageFile != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blueAccent),
              onPressed: _resetCamera,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_imageFile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.face_retouching_natural,
                  size: 80,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Trợ lý Soi Da AI",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Đưa khuôn mặt của bạn vào khung hình hoặc chọn ảnh từ thư viện. AI sẽ tự động nhận diện mụn, thâm và đưa ra lời khuyên.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 40),

              if (!_isModelReady) ...[
                if (_modelError == null)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Đang chuẩn bị model AI...'),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        _modelError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      TextButton.icon(
                        onPressed: _initAI,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tải lại model'),
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
              ],

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isModelReady
                            ? () => _pickImage(ImageSource.camera)
                            : null,
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text(
                          'Chụp ảnh',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                          shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isModelReady
                            ? () => _pickImage(ImageSource.gallery)
                            : null,
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.blueAccent,
                        ),
                        label: const Text(
                          'Thư viện',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Colors.blueAccent,
                              width: 1.5,
                            ),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 150),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_imageFile!, fit: BoxFit.cover),

                      if (_showResult && _imageSize != null)
                        CustomPaint(
                          painter: AcneBoundingBoxPainter(
                            boxes: _detectedBoxes,
                            imageSize: _imageSize!,
                            widgetSize: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                          ),
                        ),

                      if (_isScanning)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanAnimation.value * 380,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  Container(
                                    height: 3,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.cyanAccent.withValues(
                                            alpha: 0.8,
                                          ),
                                          blurRadius: 15,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 50,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.cyanAccent.withValues(
                                            alpha: 0.3,
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 30),

          if (_isScanning)
            const Column(
              children: [
                CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 15),
                Text(
                  "Trí tuệ nhân tạo đang phân tích...",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            )
          else if (_showResult)
            _buildResultPanel(),
        ],
      ),
    );
  }

  // ==========================================
  // UI: BẢNG KẾT QUẢ VÀ HỆ CHUYÊN GIA
  // ==========================================
  Widget _buildResultPanel() {
    int acneCount = _detectedBoxes.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Báo cáo tình trạng da",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  "$acneCount nốt",
                  "Phát hiện",
                  Icons.coronavirus,
                  Colors.redAccent,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildInfoCard(
                  acneCount > 5 ? "Cần chú ý" : "Khá ổn",
                  "Trạng thái",
                  Icons.health_and_safety,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  "5 Trạng thái",
                  "Phân loại",
                  Icons.category,
                  Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildInfoCard(
                  "Deep Learning",
                  "Engine",
                  Icons.memory,
                  Colors.purpleAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          const Text(
            "Kết quả sau khi phân tích",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          Builder(
            builder: (context) {
              final advice = _applyExpertSystem(acneCount);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExpertRow(
                      Icons.analytics,
                      "Đánh giá:",
                      advice.level,
                      Colors.blue,
                    ),
                    const Divider(height: 20),
                    _buildExpertRow(
                      Icons.wb_sunny,
                      "Buổi sáng:",
                      advice.morningRoutine,
                      Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _buildExpertRow(
                      Icons.nightlight_round,
                      "Buổi tối:",
                      advice.nightRoutine,
                      Colors.indigo,
                    ),
                    const Divider(height: 20),
                    _buildExpertRow(
                      Icons.science,
                      "Hoạt chất khuyên dùng:",
                      advice.activeIngredients,
                      Colors.green,
                    ),
                    const SizedBox(height: 10),
                    _buildExpertRow(
                      Icons.warning_amber_rounded,
                      "Lưu ý:",
                      advice.warning,
                      Colors.redAccent,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final image = _imageFile;
                final user = FirebaseAuth.instance.currentUser;
                if (image == null || user == null) return;
                final advice = _applyExpertSystem(acneCount);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ScanHistoryStore.save(
                    userId: user.uid,
                    sourceImage: image,
                    acneCount: acneCount,
                    level: advice.level,
                    morningRoutine: advice.morningRoutine,
                    nightRoutine: advice.nightRoutine,
                    activeIngredients: advice.activeIngredients,
                    warning: advice.warning,
                  );
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đã lưu ảnh và kết quả vào Lịch sử soi da!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Không thể lưu kết quả. Vui lòng thử lại.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_alt, color: Colors.blueAccent),
              label: const Text(
                'Lưu kết quả này',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper vẽ từng dòng của Hệ chuyên gia
  Widget _buildExpertRow(
    IconData icon,
    String title,
    String content,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: "$title ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: content),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Bộ Suy Diễn
  ExpertAdvice _applyExpertSystem(int acneCount) {
    if (acneCount == 0) {
      return ExpertAdvice(
        level: "Bình thường - Duy trì bảo vệ",
        morningRoutine:
            "Sữa rửa mặt dịu nhẹ -> Toner -> Kem chống nắng (SPF 50+).",
        nightRoutine:
            "Tẩy trang -> Sữa rửa mặt -> Serum cấp ẩm (HA/B5) -> Kem dưỡng ẩm.",
        activeIngredients: "Hyaluronic Acid (Cấp ẩm), Niacinamide (Làm sáng).",
        warning: "Da đang ổn định, tránh lạm dụng tẩy tế bào chết hóa học.",
      );
    } else if (acneCount <= 3) {
      return ExpertAdvice(
        level: "Mụn nhẹ - Ưu tiên kháng viêm cục bộ",
        morningRoutine:
            "Sữa rửa mặt -> Dưỡng ẩm mỏng nhẹ -> Kem chống nắng (Oil-free).",
        nightRoutine:
            "Tẩy trang -> Sữa rửa mặt -> Chấm mụn lên nốt viêm -> Kem dưỡng phục hồi.",
        activeIngredients: "Salicylic Acid 2% (BHA), Tea Tree Oil (Tràm trà).",
        warning:
            "Tuyệt đối không dùng tay nặn mụn. Chỉ bôi hoạt chất lên đúng nốt mụn.",
      );
    } else if (acneCount <= 7) {
      return ExpertAdvice(
        level: "Mụn trung bình - Kiểm soát bã nhờn toàn mặt",
        morningRoutine:
            "Sữa rửa mặt (chứa BHA/PHA) -> Serum Niacinamide -> Kem chống nắng.",
        nightRoutine:
            "Tẩy trang sâu -> Sữa rửa mặt -> Bôi mỏng Retinol/Adapalene toàn mặt (cách ngày) -> Kem dưỡng.",
        activeIngredients: "Adapalene 0.1%, Niacinamide 10%, BHA 2%.",
        warning:
            "Có thể xảy ra hiện tượng đẩy mụn (Purging) trong 2-4 tuần đầu.",
      );
    } else {
      return ExpertAdvice(
        level: "Mụn viêm nặng - Phục hồi hàng rào bảo vệ",
        morningRoutine:
            "Rửa mặt bằng nước muối sinh lý hoặc SRM cực dịu nhẹ -> Kem chống nắng vật lý.",
        nightRoutine:
            "Tẩy trang nước -> Sữa rửa mặt -> Kem dưỡng phục hồi (B5/Ceramide).",
        activeIngredients: "Panthenol (B5), Ceramide, Centella (Rau má).",
        warning:
            "DỪNG ngay các hoạt chất treatment mạnh (AHA/BHA/Retinol). Khuyến nghị thăm khám bác sĩ da liễu để kê đơn kháng sinh đường uống hoặc bôi.",
      );
    }
  }

  // Helper vẽ thẻ thông tin
  Widget _buildInfoCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ==========================================
// PAINTER ĐỂ VẼ BOX TRỰC TIẾP LÊN ẢNH
// ==========================================
class AcneBoundingBoxPainter extends CustomPainter {
  final List<AcneBox> boxes;
  final Size imageSize;
  final Size widgetSize;

  AcneBoundingBoxPainter({
    required this.boxes,
    required this.imageSize,
    required this.widgetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    double imgRatio = imageSize.width / imageSize.height;
    double widgetRatio = widgetSize.width / widgetSize.height;

    double scale;
    double dx = 0;
    double dy = 0;

    if (imgRatio > widgetRatio) {
      scale = widgetSize.height / imageSize.height;
      dx = (widgetSize.width - imageSize.width * scale) / 2;
    } else {
      scale = widgetSize.width / imageSize.width;
      dy = (widgetSize.height - imageSize.height * scale) / 2;
    }

    for (var box in boxes) {
      final rect = Rect.fromLTWH(
        box.left * scale + dx,
        box.top * scale + dy,
        box.width * scale,
        box.height * scale,
      );

      canvas.drawRect(rect, paint);

      final fillPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// CẤU TRÚC DỮ LIỆU CHO HỆ CHUYÊN GIA
// ==========================================
class ExpertAdvice {
  final String level;
  final String morningRoutine;
  final String nightRoutine;
  final String activeIngredients;
  final String warning;

  ExpertAdvice({
    required this.level,
    required this.morningRoutine,
    required this.nightRoutine,
    required this.activeIngredients,
    required this.warning,
  });
}

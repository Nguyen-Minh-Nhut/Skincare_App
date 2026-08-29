import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class AcneBox {
  final double left;
  final double top;
  final double width;
  final double height;
  final double confidence;
  final int detectorVotes;

  const AcneBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
    this.detectorVotes = 1,
  });
}

class AcneDetectionBenchmark {
  const AcneDetectionBenchmark({
    required this.boxes,
    required this.decodeMicroseconds,
    required this.yoloMicroseconds,
    required this.classifierMicroseconds,
    required this.totalMicroseconds,
    required this.candidateCount,
    required this.classifiedCount,
  });

  final List<AcneBox> boxes;
  final int decodeMicroseconds;
  final int yoloMicroseconds;
  final int classifierMicroseconds;
  final int totalMicroseconds;
  final int candidateCount;
  final int classifiedCount;
}

bool shouldRunAcneClassifier({
  required double detectorConfidence,
  double minConfidence = 0.08,
}) {
  return detectorConfidence >= minConfidence;
}

bool shouldKeepAcneDetection({
  required double detectorConfidence,
  required double normalScore,
  required double acneScore,
  int detectorVotes = 1,
  double trustedDetectorConfidence = 0.15,
}) {
  if (!normalScore.isFinite || !acneScore.isFinite) return false;

  final scoreSum = normalScore + acneScore;
  final looksLikeProbabilities =
      normalScore >= 0 &&
      acneScore >= 0 &&
      scoreSum >= 0.98 &&
      scoreSum <= 1.02;
  final acneProbability = looksLikeProbabilities
      ? acneScore / scoreSum
      : 1 / (1 + math.exp(normalScore - acneScore));
  final requiredProbability = detectorVotes >= 2
      ? 0.52
      : detectorConfidence >= trustedDetectorConfidence
      ? 0.58
      : 0.68;
  return acneProbability >= requiredProbability;
}

bool isPlausibleAcneBox(
  AcneBox box, {
  required int imageWidth,
  required int imageHeight,
  double maxSideFraction = 0.16,
  double maxAreaFraction = 0.02,
  double minAspectRatio = 0.40,
  double maxAspectRatio = 2.50,
}) {
  if (imageWidth <= 0 ||
      imageHeight <= 0 ||
      box.width <= 0 ||
      box.height <= 0) {
    return false;
  }
  final widthFraction = box.width / imageWidth;
  final heightFraction = box.height / imageHeight;
  final areaFraction = box.width * box.height / (imageWidth * imageHeight);
  final aspectRatio = box.width / box.height;
  return widthFraction <= maxSideFraction &&
      heightFraction <= maxSideFraction &&
      areaFraction <= maxAreaFraction &&
      aspectRatio >= minAspectRatio &&
      aspectRatio <= maxAspectRatio;
}

AcneBox expandBoxForClassification(
  AcneBox box, {
  required int imageWidth,
  required int imageHeight,
  double scale = 2.0,
}) {
  if (imageWidth <= 0 || imageHeight <= 0 || scale <= 0) return box;
  final centerX = box.left + box.width / 2;
  final centerY = box.top + box.height / 2;
  final expandedWidth = box.width * scale;
  final expandedHeight = box.height * scale;
  final left = (centerX - expandedWidth / 2).clamp(0.0, imageWidth.toDouble());
  final top = (centerY - expandedHeight / 2).clamp(0.0, imageHeight.toDouble());
  final right = (centerX + expandedWidth / 2).clamp(0.0, imageWidth.toDouble());
  final bottom = (centerY + expandedHeight / 2).clamp(
    0.0,
    imageHeight.toDouble(),
  );
  return AcneBox(
    left: left,
    top: top,
    width: right - left,
    height: bottom - top,
    confidence: box.confidence,
    detectorVotes: box.detectorVotes,
  );
}

double _intersectionOverUnion(AcneBox a, AcneBox b) {
  final intersectionLeft = a.left > b.left ? a.left : b.left;
  final intersectionTop = a.top > b.top ? a.top : b.top;
  final intersectionRight = a.left + a.width < b.left + b.width
      ? a.left + a.width
      : b.left + b.width;
  final intersectionBottom = a.top + a.height < b.top + b.height
      ? a.top + a.height
      : b.top + b.height;
  final intersectionWidth = intersectionRight - intersectionLeft;
  final intersectionHeight = intersectionBottom - intersectionTop;
  if (intersectionWidth <= 0 || intersectionHeight <= 0) return 0;
  final intersectionArea = intersectionWidth * intersectionHeight;
  final unionArea = a.width * a.height + b.width * b.height - intersectionArea;
  return unionArea <= 0 ? 0 : intersectionArea / unionArea;
}

double _intersectionOverSmallerArea(AcneBox a, AcneBox b) {
  final intersectionLeft = math.max(a.left, b.left);
  final intersectionTop = math.max(a.top, b.top);
  final intersectionRight = math.min(a.left + a.width, b.left + b.width);
  final intersectionBottom = math.min(a.top + a.height, b.top + b.height);
  final intersectionWidth = intersectionRight - intersectionLeft;
  final intersectionHeight = intersectionBottom - intersectionTop;
  if (intersectionWidth <= 0 || intersectionHeight <= 0) return 0;
  final smallerArea = math.min(a.width * a.height, b.width * b.height);
  return smallerArea <= 0
      ? 0
      : intersectionWidth * intersectionHeight / smallerArea;
}

List<AcneBox> combineDetectorBoxes(
  List<AcneBox> legacyBoxes,
  List<AcneBox> preferredBoxes, {
  double agreementIou = 0.15,
  double agreementContainment = 0.50,
}) {
  // YOLO11s mới là nguồn đề xuất chính. Nếu nó không trả được kết quả do
  // khác miền dữ liệu, pipeline mới dùng YOLO11m cũ làm fallback.
  if (preferredBoxes.isEmpty) return legacyBoxes;

  return preferredBoxes.map((preferred) {
    AcneBox? matchingLegacy;
    var bestAgreement = 0.0;
    for (final legacy in legacyBoxes) {
      final iou = _intersectionOverUnion(preferred, legacy);
      final containment = _intersectionOverSmallerArea(preferred, legacy);
      final agreement = math.max(iou, containment);
      if ((iou >= agreementIou || containment >= agreementContainment) &&
          agreement > bestAgreement) {
        matchingLegacy = legacy;
        bestAgreement = agreement;
      }
    }

    return AcneBox(
      left: preferred.left,
      top: preferred.top,
      width: preferred.width,
      height: preferred.height,
      confidence: matchingLegacy == null
          ? preferred.confidence
          : math.max(preferred.confidence, matchingLegacy.confidence),
      detectorVotes: matchingLegacy == null ? 1 : 2,
    );
  }).toList();
}

List<AcneBox> suppressDuplicateBoxes(
  List<AcneBox> boxes, {
  double iouThreshold = 0.30,
  double containmentThreshold = 0.70,
}) {
  final sorted = [...boxes]
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
  final kept = <AcneBox>[];
  for (final candidate in sorted) {
    if (kept.every((box) {
      final containment = _intersectionOverSmallerArea(candidate, box);
      return _intersectionOverUnion(candidate, box) < iouThreshold &&
          containment < containmentThreshold;
    })) {
      kept.add(candidate);
    }
  }
  return kept;
}

List<AcneBox> parseYoloBoxes(
  Map<String, dynamic> results, {
  required int imageWidth,
  required int imageHeight,
  double minConfidence = 0.40,
}) {
  if (imageWidth <= 0 || imageHeight <= 0) return const [];
  final rawBoxes = results['boxes'];
  if (rawBoxes is! List) return const [];

  final boxes = <AcneBox>[];
  for (final rawBox in rawBoxes) {
    if (rawBox is! Map) continue;
    final confidence = rawBox['confidence'];
    final rawX1 = rawBox['x1'];
    final rawY1 = rawBox['y1'];
    final rawX2 = rawBox['x2'];
    final rawY2 = rawBox['y2'];
    if (confidence is! num ||
        rawX1 is! num ||
        rawY1 is! num ||
        rawX2 is! num ||
        rawY2 is! num) {
      continue;
    }

    final score = confidence.toDouble();
    if (!score.isFinite || score < minConfidence) continue;
    final x1 = rawX1.toDouble().clamp(0.0, imageWidth.toDouble());
    final y1 = rawY1.toDouble().clamp(0.0, imageHeight.toDouble());
    final x2 = rawX2.toDouble().clamp(0.0, imageWidth.toDouble());
    final y2 = rawY2.toDouble().clamp(0.0, imageHeight.toDouble());
    if (![x1, y1, x2, y2].every((value) => value.isFinite) ||
        x2 <= x1 ||
        y2 <= y1) {
      continue;
    }

    boxes.add(
      AcneBox(
        left: x1,
        top: y1,
        width: x2 - x1,
        height: y2 - y1,
        confidence: score,
      ),
    );
  }
  return boxes;
}

class AcneDetectorPipeline {
  AcneDetectorPipeline._(
    this._legacyDetector,
    this._preferredDetector,
    this._classifier,
  );

  final YOLO _legacyDetector;
  final YOLO _preferredDetector;
  final Interpreter _classifier;
  bool _loaded = false;
  bool _disposed = false;

  static const String _yoloPath = 'assets/models/acne_detector.tflite';
  static const String _preferredYoloPath =
      'assets/models/yolo11s_best_w8a32.tflite';
  static const String _cnnPath = 'assets/models/model_phan_loai_mun.tflite';

  static Future<AcneDetectorPipeline> create() async {
    final legacyDetector = YOLO(modelPath: _yoloPath, task: YOLOTask.detect);
    final preferredDetector = YOLO(
      modelPath: _preferredYoloPath,
      task: YOLOTask.detect,
    );
    final classifier = await Interpreter.fromAsset(_cnnPath);
    final inputShape = classifier.getInputTensor(0).shape;
    final outputShape = classifier.getOutputTensor(0).shape;
    if (!listEquals(inputShape, const [1, 3, 224, 224]) ||
        outputShape.isEmpty ||
        outputShape.last < 2) {
      classifier.close();
      throw StateError(
        'Unexpected classifier shape: input=$inputShape, output=$outputShape',
      );
    }

    final pipeline = AcneDetectorPipeline._(
      legacyDetector,
      preferredDetector,
      classifier,
    );
    try {
      await pipeline._ensureLoaded();
      return pipeline;
    } catch (_) {
      await pipeline.dispose();
      rethrow;
    }
  }

  Future<void> _ensureLoaded() async {
    if (_disposed) throw StateError('Acne detector đã được giải phóng.');
    if (_loaded) return;
    if (!await _legacyDetector.loadModel()) {
      throw StateError('Không thể tải YOLO11m.');
    }
    if (!await _preferredDetector.loadModel()) {
      throw StateError('Không thể tải YOLO11s bổ sung.');
    }
    _loaded = true;
  }

  Float32List _imageToTensor(img.Image image) {
    final resized = img.copyResize(image, width: 224, height: 224);
    final input = Float32List(3 * 224 * 224);
    var pixelIndex = 0;
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex] = (pixel.r / 255.0 - 0.485) / 0.229;
        input[pixelIndex + (224 * 224)] = (pixel.g / 255.0 - 0.456) / 0.224;
        input[pixelIndex + (2 * 224 * 224)] = (pixel.b / 255.0 - 0.406) / 0.225;
        pixelIndex++;
      }
    }
    return input;
  }

  Future<List<AcneBox>> detectAndFilter(
    Uint8List imageBytes, {
    double minConfidence = 0.08,
    double trustedDetectorConfidence = 0.15,
  }) async {
    final benchmark = await detectAndFilterWithBenchmark(
      imageBytes,
      minConfidence: minConfidence,
      trustedDetectorConfidence: trustedDetectorConfidence,
    );
    return benchmark.boxes;
  }

  Future<AcneDetectionBenchmark> detectAndFilterWithBenchmark(
    Uint8List imageBytes, {
    double minConfidence = 0.08,
    double trustedDetectorConfidence = 0.15,
  }) async {
    final totalWatch = Stopwatch()..start();
    await _ensureLoaded();
    final finalBoxes = <AcneBox>[];
    final yoloWatch = Stopwatch()..start();
    final legacyResults = await _legacyDetector.predict(
      imageBytes,
      confidenceThreshold: minConfidence,
    );
    final preferredResults = await _preferredDetector.predict(
      imageBytes,
      confidenceThreshold: minConfidence,
    );
    yoloWatch.stop();

    final decodeWatch = Stopwatch()..start();
    final originalImg = img.decodeImage(imageBytes);
    decodeWatch.stop();
    if (originalImg == null) {
      totalWatch.stop();
      return AcneDetectionBenchmark(
        boxes: const [],
        decodeMicroseconds: decodeWatch.elapsedMicroseconds,
        yoloMicroseconds: yoloWatch.elapsedMicroseconds,
        classifierMicroseconds: 0,
        totalMicroseconds: totalWatch.elapsedMicroseconds,
        candidateCount: 0,
        classifiedCount: 0,
      );
    }
    final legacyCandidates = parseYoloBoxes(
      legacyResults,
      imageWidth: originalImg.width,
      imageHeight: originalImg.height,
      minConfidence: minConfidence,
    );
    final preferredCandidates = parseYoloBoxes(
      preferredResults,
      imageWidth: originalImg.width,
      imageHeight: originalImg.height,
      minConfidence: minConfidence,
    );
    final rawCandidates = combineDetectorBoxes(
      legacyCandidates,
      preferredCandidates,
    );
    final candidates = rawCandidates
        .where(
          (box) => isPlausibleAcneBox(
            box,
            imageWidth: originalImg.width,
            imageHeight: originalImg.height,
          ),
        )
        .toList();
    final agreedCount = candidates
        .where((box) => box.detectorVotes >= 2)
        .length;
    debugPrint(
      'AI detector: ${candidates.length} vùng từ YOLO11s, '
      '$agreedCount vùng được YOLO11m xác nhận.',
    );

    var classifiedCount = 0;
    final classifierWatch = Stopwatch()..start();
    for (final box in candidates) {
      final classifierBox = expandBoxForClassification(
        box,
        imageWidth: originalImg.width,
        imageHeight: originalImg.height,
      );
      final cropX = classifierBox.left.floor();
      final cropY = classifierBox.top.floor();
      final cropWidth = classifierBox.width.ceil().clamp(
        1,
        originalImg.width - cropX,
      );
      final cropHeight = classifierBox.height.ceil().clamp(
        1,
        originalImg.height - cropY,
      );

      // Tất cả detection đều phải được MobileNetV2 xác thực. Confidence cao
      // của YOLO không đủ để giữ một vùng nếu classifier nhận đó là da thường.
      if (!shouldRunAcneClassifier(
        detectorConfidence: box.confidence,
        minConfidence: minConfidence,
      )) {
        continue;
      }

      classifiedCount++;
      final croppedImg = img.copyCrop(
        originalImg,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      try {
        final input = _imageToTensor(croppedImg).reshape([1, 3, 224, 224]);
        final output = List<double>.filled(2, 0).reshape([1, 2]);
        _classifier.run(input, output);
        final normalScore = (output[0][0] as num).toDouble();
        final acneScore = (output[0][1] as num).toDouble();
        debugPrint(
          'AI classifier: normal=${normalScore.toStringAsFixed(3)}, '
          'acne=${acneScore.toStringAsFixed(3)}',
        );

        if (shouldKeepAcneDetection(
          detectorConfidence: box.confidence,
          normalScore: normalScore,
          acneScore: acneScore,
          detectorVotes: box.detectorVotes,
          trustedDetectorConfidence: trustedDetectorConfidence,
        )) {
          finalBoxes.add(
            AcneBox(
              // Chỉ crop phân loại được mở rộng; khung hiển thị vẫn dùng
              // đúng tọa độ tổn thương mà YOLO dự đoán.
              left: box.left,
              top: box.top,
              width: box.width,
              height: box.height,
              confidence: box.confidence,
              detectorVotes: box.detectorVotes,
            ),
          );
        }
      } catch (error) {
        debugPrint('Lỗi phân loại vùng da: $error');
        // Fail closed: classifier lỗi thì không được biến YOLO false-positive
        // thành kết quả chẩn đoán hiển thị cho người dùng.
      }
    }
    classifierWatch.stop();

    final deduplicated = suppressDuplicateBoxes(finalBoxes);
    debugPrint(
      'AI result: ${deduplicated.length}/${finalBoxes.length}/'
      '${candidates.length} vùng (sau gộp/đã lọc/YOLO).',
    );
    totalWatch.stop();
    return AcneDetectionBenchmark(
      boxes: deduplicated,
      decodeMicroseconds: decodeWatch.elapsedMicroseconds,
      yoloMicroseconds: yoloWatch.elapsedMicroseconds,
      classifierMicroseconds: classifierWatch.elapsedMicroseconds,
      totalMicroseconds: totalWatch.elapsedMicroseconds,
      candidateCount: candidates.length,
      classifiedCount: classifiedCount,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _classifier.close();
    await _legacyDetector.dispose();
    await _preferredDetector.dispose();
  }
}

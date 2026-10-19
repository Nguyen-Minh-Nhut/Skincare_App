import 'dart:math' as math;
import 'dart:isolate';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

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

bool shouldTrustYoloDetection({
  required double detectorConfidence,
  double? widthFraction,
  double? heightFraction,
  double trustedDetectorConfidence = 0.15,
}) {
  final lesionSized =
      (widthFraction == null || widthFraction <= 0.08) &&
      (heightFraction == null || heightFraction <= 0.08);
  return detectorConfidence >= trustedDetectorConfidence && lesionSized;
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
  final centerX = (box.left + box.width / 2) / imageWidth;
  final centerY = (box.top + box.height / 2) / imageHeight;
  // Selfie phân tích da phải nằm trong vùng mặt trung tâm. Ellipse này loại
  // đèn, trần, nền và phần tóc ở các góc mà detector dễ nhận nhầm thành mụn.
  final normalizedFaceDistance =
      math.pow((centerX - 0.5) / 0.44, 2) +
      math.pow((centerY - 0.52) / 0.50, 2);
  return widthFraction <= maxSideFraction &&
      heightFraction <= maxSideFraction &&
      areaFraction <= maxAreaFraction &&
      aspectRatio >= minAspectRatio &&
      aspectRatio <= maxAspectRatio &&
      centerY >= 0.06 &&
      normalizedFaceDistance <= 1.0;
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

/// Decode this model's normalized xywh output and undo letterboxing.
List<AcneBox> decodeYoloTensor(
  List<List<double>> channels, {
  required int imageWidth,
  required int imageHeight,
  double minConfidence = .08,
}) {
  if (imageWidth <= 0 ||
      imageHeight <= 0 ||
      channels.length != 5 ||
      channels.any((row) => row.length != channels.first.length)) {
    throw const FormatException('Invalid YOLO output');
  }
  const side = 640;
  final gain = math.min(side / imageWidth, side / imageHeight);
  final px = ((side - (imageWidth * gain).round()) / 2).floor();
  final py = ((side - (imageHeight * gain).round()) / 2).floor();
  final boxes = <AcneBox>[];
  for (var i = 0; i < channels.first.length; i++) {
    final values = channels.map((row) => row[i]).toList();
    if (values.any((v) => !v.isFinite) || values[4] < minConfidence) continue;
    final cx = values[0] * side, cy = values[1] * side;
    final w = values[2] * side, h = values[3] * side;
    final x1 = ((cx - w / 2 - px) / gain).clamp(0.0, imageWidth.toDouble());
    final y1 = ((cy - h / 2 - py) / gain).clamp(0.0, imageHeight.toDouble());
    final x2 = ((cx + w / 2 - px) / gain).clamp(0.0, imageWidth.toDouble());
    final y2 = ((cy + h / 2 - py) / gain).clamp(0.0, imageHeight.toDouble());
    if (x2 <= x1 || y2 <= y1) continue;
    boxes.add(
      AcneBox(
        left: x1,
        top: y1,
        width: x2 - x1,
        height: y2 - y1,
        confidence: values[4],
      ),
    );
  }
  return suppressDuplicateBoxes(
    boxes,
    iouThreshold: .7,
    containmentThreshold: 1.01,
  );
}

/// The worker owns its interpreters for their entire lifetime. Never re-wrap
/// their addresses in another isolate: dynamic tensors can be invalidated.
class AcneDetectorPipeline {
  AcneDetectorPipeline._(this._isolate, this._port, this._directory);
  final Directory _directory;
  final Isolate _isolate;
  final SendPort _port;
  bool _disposed = false;

  static Future<AcneDetectorPipeline> create() async {
    final yolo = await rootBundle.load(
      'assets/models/acne_detector_mobile.tflite',
    );
    final cnn = await rootBundle.load(
      'assets/models/model_phan_loai_mun.tflite',
    );
    // Use the numerically identical, inline-buffer mobile package. Keep model
    // files alive until the worker closes its file-backed interpreters.
    final directory = await (await getTemporaryDirectory()).createTemp(
      'scan_models_',
    );
    final yoloFile = File('${directory.path}/detector.tflite');
    final cnnFile = File('${directory.path}/classifier.tflite');
    try {
      await yoloFile.writeAsBytes(
        yolo.buffer.asUint8List(yolo.offsetInBytes, yolo.lengthInBytes),
        flush: true,
      );
      await cnnFile.writeAsBytes(
        cnn.buffer.asUint8List(cnn.offsetInBytes, cnn.lengthInBytes),
        flush: true,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
    final ready = ReceivePort();
    final isolate = await Isolate.spawn(_scanWorker, [
      ready.sendPort,
      yoloFile.path,
      cnnFile.path,
    ]);
    try {
      final response = await ready.first.timeout(const Duration(seconds: 60));
      if (response is! SendPort) {
        throw StateError('Could not load scan models: $response');
      }
      return AcneDetectorPipeline._(isolate, response, directory);
    } catch (_) {
      isolate.kill(priority: Isolate.immediate);
      await directory.delete(recursive: true);
      rethrow;
    } finally {
      ready.close();
    }
  }

  Future<List<AcneBox>> detectAndFilter(
    Uint8List bytes, {
    double minConfidence = .08,
    double trustedDetectorConfidence = .15,
  }) async => (await detectAndFilterWithBenchmark(
    bytes,
    minConfidence: minConfidence,
    trustedDetectorConfidence: trustedDetectorConfidence,
  )).boxes;

  Future<AcneDetectionBenchmark> detectAndFilterWithBenchmark(
    Uint8List bytes, {
    double minConfidence = .08,
    double trustedDetectorConfidence = .15,
  }) async {
    if (_disposed) throw StateError('Scan worker is closed');
    final reply = ReceivePort();
    _port.send([
      reply.sendPort,
      bytes,
      minConfidence,
      trustedDetectorConfidence,
    ]);
    try {
      final response = await reply.first.timeout(const Duration(seconds: 120));
      if (response is AcneDetectionBenchmark) return response;
      throw StateError('Scan failed: $response');
    } on TimeoutException {
      _disposed = true;
      _isolate.kill(priority: Isolate.immediate);
      // Keep mapped files until worker teardown; cache cleanup is safe later.
      rethrow;
    } finally {
      reply.close();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final reply = ReceivePort();
    _port.send([reply.sendPort, null]);
    try {
      await reply.first.timeout(const Duration(seconds: 5));
    } catch (_) {
      _isolate.kill(priority: Isolate.immediate);
    } finally {
      reply.close();
      try {
        await _directory.delete(recursive: true);
      } catch (_) {
        /* Cache cleanup can retry on a later OS cleanup. */
      }
    }
  }
}

Future<void> _scanWorker(List<dynamic> arguments) async {
  final ready = arguments[0] as SendPort;
  _AcneDetectorEngine engine;
  try {
    engine = _AcneDetectorEngine.create(
      arguments[1] as String,
      arguments[2] as String,
    );
  } catch (error) {
    ready.send(error.toString());
    return;
  }
  final requests = ReceivePort();
  ready.send(requests.sendPort);
  await for (final message in requests) {
    final request = message as List;
    final reply = request[0] as SendPort;
    if (request[1] == null) {
      await engine.dispose();
      reply.send(true);
      requests.close();
      break;
    }
    try {
      reply.send(
        await engine.detectAndFilterWithBenchmark(
          request[1] as Uint8List,
          minConfidence: request[2] as double,
          trustedDetectorConfidence: request[3] as double,
        ),
      );
    } catch (error) {
      reply.send(error.toString());
    }
  }
}

class _AcneDetectorEngine {
  _AcneDetectorEngine._(this._detector, this._classifier);

  final Interpreter _detector;
  final Interpreter _classifier;
  bool _disposed = false;

  static _AcneDetectorEngine create(String yoloPath, String cnnPath) {
    final detector = Interpreter.fromFile(File(yoloPath));
    Interpreter classifier;
    try {
      if (!listEquals(detector.getInputTensor(0).shape, const [
            1,
            3,
            640,
            640,
          ]) ||
          !listEquals(detector.getOutputTensor(0).shape, const [1, 5, 8400])) {
        throw StateError('Unexpected YOLO tensor shapes');
      }
      classifier = Interpreter.fromFile(File(cnnPath));
    } catch (_) {
      detector.close();
      rethrow;
    }
    final inputShape = classifier.getInputTensor(0).shape;
    final outputShape = classifier.getOutputTensor(0).shape;
    if (!listEquals(inputShape, const [1, 3, 224, 224]) ||
        outputShape.isEmpty ||
        outputShape.last < 2) {
      classifier.close();
      detector.close();
      throw StateError(
        'Unexpected classifier shape: input=$inputShape, output=$outputShape',
      );
    }

    return _AcneDetectorEngine._(detector, classifier);
  }

  Future<List<AcneBox>> _detect(img.Image image, double minConfidence) async {
    const side = 640;
    final gain = math.min(side / image.width, side / image.height);
    final width = (image.width * gain).round();
    final height = (image.height * gain).round();
    final left = ((side - width) / 2).floor();
    final top = ((side - height) / 2).floor();
    final resized = img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
    final input = Float32List(3 * side * side)
      ..fillRange(0, 3 * side * side, 114 / 255);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = resized.getPixel(x, y);
        final index = (y + top) * side + x + left;
        input[index] = pixel.r / 255;
        input[index + side * side] = pixel.g / 255;
        input[index + 2 * side * side] = pixel.b / 255;
      }
    }
    final output = List<double>.filled(5 * 8400, 0).reshape([1, 5, 8400]);
    _detector.run(input.reshape([1, 3, side, side]), output);
    final channels = (output[0] as List)
        .map((row) => List<double>.from(row as List))
        .toList();
    return decodeYoloTensor(
      channels,
      imageWidth: image.width,
      imageHeight: image.height,
      minConfidence: minConfidence,
    );
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
    if (_disposed) throw StateError('Acne detector đã được giải phóng.');
    final finalBoxes = <AcneBox>[];
    final decodeWatch = Stopwatch()..start();
    final originalImg = img.decodeImage(imageBytes);
    decodeWatch.stop();
    if (originalImg == null) throw const FormatException('Invalid image');
    final yoloWatch = Stopwatch()..start();
    final rawCandidates = await _detect(originalImg, minConfidence);
    yoloWatch.stop();
    final candidates = rawCandidates
        .where(
          (box) => isPlausibleAcneBox(
            box,
            imageWidth: originalImg.width,
            imageHeight: originalImg.height,
          ),
        )
        .toList();
    debugPrint('AI detector: ${candidates.length} vùng từ YOLO11m.');

    var classifiedCount = 0;
    final classifierWatch = Stopwatch()..start();
    for (final box in candidates) {
      if (shouldTrustYoloDetection(
        detectorConfidence: box.confidence,
        widthFraction: box.width / originalImg.width,
        heightFraction: box.height / originalImg.height,
        trustedDetectorConfidence: trustedDetectorConfidence,
      )) {
        finalBoxes.add(box);
        continue;
      }

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

      // Vùng yếu hoặc chỉ một YOLO phát hiện phải qua MobileNetV2 để giảm
      // dương tính giả. Vùng mạnh được cả hai YOLO đồng thuận đã giữ ở trên.
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
        // A broken classifier must not appear as a successful zero-spot scan.
        throw StateError('Could not classify a candidate region');
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
    _detector.close();
  }
}

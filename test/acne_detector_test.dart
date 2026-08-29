import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/screens/home/acne_detector.dart';

void main() {
  group('shouldKeepAcneDetection', () {
    test('rejects a strong YOLO detection when classifier disagrees', () {
      expect(
        shouldKeepAcneDetection(
          detectorConfidence: 0.72,
          normalScore: 0.8,
          acneScore: 0.2,
        ),
        isFalse,
      );
    });

    test('keeps a weak detection only when classifier confirms acne', () {
      expect(
        shouldKeepAcneDetection(
          detectorConfidence: 0.12,
          normalScore: 0.25,
          acneScore: 0.75,
        ),
        isTrue,
      );
      expect(
        shouldKeepAcneDetection(
          detectorConfidence: 0.12,
          normalScore: 0.7,
          acneScore: 0.3,
        ),
        isFalse,
      );
    });
  });

  group('shouldRunAcneClassifier', () {
    test('classifies every detection at or above the YOLO threshold', () {
      expect(shouldRunAcneClassifier(detectorConfidence: 0.079), isFalse);
      expect(shouldRunAcneClassifier(detectorConfidence: 0.08), isTrue);
      expect(shouldRunAcneClassifier(detectorConfidence: 0.149), isTrue);
      expect(shouldRunAcneClassifier(detectorConfidence: 0.15), isTrue);
      expect(shouldRunAcneClassifier(detectorConfidence: 0.90), isTrue);
    });
  });

  group('isPlausibleAcneBox', () {
    test('rejects oversized face-part boxes and keeps lesion-sized boxes', () {
      expect(
        isPlausibleAcneBox(
          const AcneBox(
            left: 100,
            top: 100,
            width: 190,
            height: 180,
            confidence: 0.9,
          ),
          imageWidth: 1000,
          imageHeight: 1000,
        ),
        isFalse,
      );
      expect(
        isPlausibleAcneBox(
          const AcneBox(
            left: 100,
            top: 100,
            width: 45,
            height: 50,
            confidence: 0.4,
          ),
          imageWidth: 1000,
          imageHeight: 1000,
        ),
        isTrue,
      );
    });

    test('rejects very elongated detections', () {
      expect(
        isPlausibleAcneBox(
          const AcneBox(
            left: 10,
            top: 10,
            width: 100,
            height: 15,
            confidence: 0.7,
          ),
          imageWidth: 1000,
          imageHeight: 1000,
        ),
        isFalse,
      );
    });
  });

  group('suppressDuplicateBoxes', () {
    test('keeps the strongest overlapping box and preserves separate acne', () {
      const boxes = [
        AcneBox(left: 10, top: 10, width: 30, height: 30, confidence: 0.6),
        AcneBox(left: 12, top: 12, width: 30, height: 30, confidence: 0.9),
        AcneBox(left: 70, top: 70, width: 15, height: 15, confidence: 0.4),
      ];

      final result = suppressDuplicateBoxes(boxes);

      expect(result, hasLength(2));
      expect(result.first.confidence, 0.9);
      expect(result.last.left, 70);
    });

    test('removes a lower-confidence box nested inside another box', () {
      const boxes = [
        AcneBox(left: 10, top: 10, width: 40, height: 40, confidence: 0.9),
        AcneBox(left: 18, top: 18, width: 12, height: 12, confidence: 0.6),
      ];

      expect(suppressDuplicateBoxes(boxes), hasLength(1));
    });
  });

  group('parseYoloBoxes', () {
    test('filters malformed and low-confidence detections', () {
      final boxes = parseYoloBoxes(
        {
          'boxes': [
            {'x1': 10, 'y1': 20, 'x2': 40, 'y2': 60, 'confidence': 0.8},
            {'x1': 1, 'y1': 2, 'x2': 3, 'y2': 4, 'confidence': 0.2},
            {'x1': 'bad', 'y1': 2, 'x2': 3, 'y2': 4, 'confidence': 0.9},
            {'x1': 10, 'y1': 10, 'x2': 5, 'y2': 20, 'confidence': 0.9},
          ],
        },
        imageWidth: 100,
        imageHeight: 100,
        minConfidence: 0.4,
      );

      expect(boxes, hasLength(1));
      expect(boxes.single.left, 10);
      expect(boxes.single.top, 20);
      expect(boxes.single.width, 30);
      expect(boxes.single.height, 40);
      expect(boxes.single.confidence, 0.8);
    });

    test('clips detections to image boundaries', () {
      final boxes = parseYoloBoxes(
        {
          'boxes': [
            {'x1': -20, 'y1': -10, 'x2': 140, 'y2': 80, 'confidence': 1},
          ],
        },
        imageWidth: 100,
        imageHeight: 60,
      );

      expect(boxes, hasLength(1));
      expect(boxes.single.left, 0);
      expect(boxes.single.top, 0);
      expect(boxes.single.width, 100);
      expect(boxes.single.height, 60);
    });

    test('returns an empty list when boxes are absent', () {
      expect(parseYoloBoxes({}, imageWidth: 100, imageHeight: 100), isEmpty);
    });
  });
}

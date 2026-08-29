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

    test('uses detector agreement without bypassing MobileNetV2', () {
      expect(
        shouldKeepAcneDetection(
          detectorConfidence: 0.2,
          normalScore: 0.45,
          acneScore: 0.55,
          detectorVotes: 2,
        ),
        isTrue,
      );
      expect(
        shouldKeepAcneDetection(
          detectorConfidence: 0.9,
          normalScore: 0.8,
          acneScore: 0.2,
          detectorVotes: 2,
        ),
        isFalse,
      );
    });
  });

  group('combineDetectorBoxes', () {
    test('marks overlapping YOLO boxes as two-model agreement', () {
      const legacy = [
        AcneBox(left: 10, top: 10, width: 30, height: 30, confidence: 0.4),
      ];
      const preferred = [
        AcneBox(left: 12, top: 12, width: 28, height: 28, confidence: 0.6),
      ];

      final result = combineDetectorBoxes(legacy, preferred);

      expect(result, hasLength(1));
      expect(result.single.detectorVotes, 2);
      expect(result.single.confidence, 0.6);
      expect(result.single.left, 12);
    });

    test('keeps YOLO11s proposals and does not add unmatched legacy boxes', () {
      const legacy = [
        AcneBox(left: 80, top: 80, width: 15, height: 15, confidence: 0.9),
      ];
      const preferred = [
        AcneBox(left: 10, top: 10, width: 12, height: 12, confidence: 0.5),
      ];

      final result = combineDetectorBoxes(legacy, preferred);

      expect(result, hasLength(1));
      expect(result.single.left, 10);
      expect(result.single.detectorVotes, 1);
    });

    test('falls back to legacy detector when YOLO11s returns no boxes', () {
      const legacy = [
        AcneBox(left: 20, top: 20, width: 10, height: 10, confidence: 0.4),
      ];

      expect(combineDetectorBoxes(legacy, const []), same(legacy));
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

  group('expandBoxForClassification', () {
    test(
      'adds surrounding skin context while preserving detector metadata',
      () {
        const box = AcneBox(
          left: 40,
          top: 50,
          width: 20,
          height: 10,
          confidence: 0.7,
          detectorVotes: 2,
        );

        final expanded = expandBoxForClassification(
          box,
          imageWidth: 200,
          imageHeight: 200,
        );

        expect(expanded.left, 30);
        expect(expanded.top, 45);
        expect(expanded.width, 40);
        expect(expanded.height, 20);
        expect(expanded.confidence, 0.7);
        expect(expanded.detectorVotes, 2);
      },
    );

    test('clips the expanded crop to image boundaries', () {
      final expanded = expandBoxForClassification(
        const AcneBox(left: 0, top: 0, width: 20, height: 20, confidence: 0.5),
        imageWidth: 100,
        imageHeight: 100,
      );

      expect(expanded.left, 0);
      expect(expanded.top, 0);
      expect(expanded.width, 30);
      expect(expanded.height, 30);
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

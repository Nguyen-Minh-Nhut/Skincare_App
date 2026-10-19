import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/services/scan_input_check.dart';

void main() {
  Map<String, dynamic> face({
    double roll = 0,
    double yaw = 0,
    double pitch = 0,
    double width = .5,
  }) => {'roll': roll, 'yaw': yaw, 'pitch': pitch, 'widthFraction': width};
  test(
    'single face gate rejects missing, multiple, rotated and distant faces',
    () {
      expect(scanFaceIssue([]), 'no-face');
      expect(scanFaceIssue([face(), face()]), 'multiple-faces');
      expect(scanFaceIssue([face(roll: 180)]), 'face-angle');
      expect(scanFaceIssue([face(yaw: 60)]), 'face-angle');
      expect(scanFaceIssue([face(width: .1)]), 'face-small');
      expect(scanFaceIssue([face()]), isNull);
    },
  );
  test('malformed face observations fail closed', () {
    expect(scanFaceIssue([{}]), 'check-failed');
    expect(scanFaceIssue([face(roll: double.nan)]), 'check-failed');
  });
}

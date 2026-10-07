import 'package:flutter_test/flutter_test.dart';
import 'package:g_point/core/app_controller.dart';

void main() {
  test('G-PLAY POINT strings are available', () {
    const s = AppStrings(true);
    expect(s.appName, 'G-PLAY POINT');
    expect(s.addPoints.isNotEmpty, true);
    expect(s.createdBy.contains('SA SABIT KHAN'), true);
  });
}

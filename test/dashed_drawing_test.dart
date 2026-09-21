import 'dart:ui' as ui;

import 'package:exsurgat/src/drawing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dashed drawing', () {
    test('dashify splits a line into on/off segments', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final builder =
          canvas.beginPath(
              strokeWidth: 1,
              color: const ui.Color(0xFF000000),
              dashPattern: [10, 5],
            )
            ..moveTo(0, 0)
            ..lineTo(100, 0)
            ..stroke();

      final path = builder.debugDashPath;
      final metrics = path.computeMetrics().toList();
      // 100 length, pattern 10/5 -> 7 full dashes (10 each) + partial.
      expect(metrics, isNotEmpty);
      final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
      expect(total, closeTo(70, 0.5));
    });

    test('solid stroke when pattern empty', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final builder =
          canvas.beginPath(
              strokeWidth: 1,
              color: const ui.Color(0xFF000000),
              dashPattern: [],
            )
            ..moveTo(0, 0)
            ..lineTo(100, 0)
            ..stroke();

      final metrics = builder.debugDashPath.computeMetrics().toList();
      expect(metrics, hasLength(1));
      expect(metrics.first.length, closeTo(100, 0.001));
    });

    test('dashed rect perimeter is dashed', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawDashedRect(
        rect: const ui.Rect.fromLTWH(10, 10, 80, 60),
        strokeWidth: 1,
        color: const ui.Color(0xFF000000),
        dashPattern: [4, 4],
      );
    });

    test('builder rect() traces closed rect outline', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final builder =
          canvas.beginPath(strokeWidth: 1, color: const ui.Color(0xFF000000))
            ..rect(const ui.Rect.fromLTWH(0, 0, 50, 20))
            ..stroke();

      final metrics = builder.debugDashPath.computeMetrics().toList();
      expect(metrics, hasLength(1));
      // Perimeter of 50x20 rect.
      expect(metrics.first.length, closeTo(140, 0.001));
    });
  });
}

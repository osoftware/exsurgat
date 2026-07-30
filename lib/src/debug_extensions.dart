import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'chant_context.dart';
import 'elements/chant_layout_element.dart';

extension DebugExtensions on ChantContext {
  void debugRect(ChantLayoutElement element, ui.Color color) {
    if (kDebugMode) {
      canvas.drawRect(
        ui.Rect.fromLTWH(
          element.bounds.x,
          element.bounds.y,
          element.bounds.width,
          element.bounds.height,
        ),
        ui.Paint()
          ..color = color
          ..style = .stroke,
      );
      canvas.drawPoints(
        .points,
        [ui.Offset(element.origin.x, element.origin.y)],
        ui.Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = .round,
      );
    }
  }
}

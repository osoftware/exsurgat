import 'package:flutter/widgets.dart';

import '../chant_score.dart';
import '../drawing.dart' show ChantContext;

class ChantPainter extends CustomPainter {
  final ChantScore score;
  final ChantContext ctxt;

  ChantPainter(this.score, this.ctxt);

  @override
  void paint(Canvas canvas, Size size) {
    ctxt.attachCanvas(canvas);
    score.draw(ctxt);
  }

  @override
  bool shouldRepaint(ChantPainter oldDelegate) => oldDelegate.score != score;

  @override
  bool shouldRebuildSemantics(ChantPainter oldDelegate) => false;
}

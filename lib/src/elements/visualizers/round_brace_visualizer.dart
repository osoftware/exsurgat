import 'dart:ui';

import 'package:xml/xml.dart';

import '../../chant_context.dart';
import '../../core.dart' as core;
import '../../drawing.dart';
import '../../quick_svg.dart';
import '../chant_layout_element.dart';

class RoundBraceVisualizer extends ChantLayoutElement {
  RoundBraceVisualizer(
    ChantContext ctxt,
    double x1,
    double x2,
    double y,
    this.isAbove,
  ) {
    ignoreBounds = true;
    if (x1 > x2) {
      final temp = x1;
      x1 = x2;
      x2 = temp;
    }
    braceHeight = (3 * ctxt.staffInterval) / 2;
    bounds = core.Rect.fromXYWH(
      x1,
      isAbove ? y - braceHeight : y,
      x2 - x1,
      braceHeight,
    );
    origin = const core.Point(0, 0);
  }

  late bool isAbove;
  late double braceHeight;

  @override
  void draw(ChantContext ctxt) {
    final points = getPathPoints();
    final path = Path()
      ..moveTo(points['x1'] as double, points['y'] as double)
      ..cubicTo(
        points['cx1'] as double,
        points['cy'] as double,
        points['cx2'] as double,
        points['cy'] as double,
        points['x2'] as double,
        points['y'] as double,
      );
    final paint = Paint()
      ..color = ctxt.theme.neumeLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = ctxt.staffLineWeight;
    ctxt.canvas.drawPath(path, paint);
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createNode('path', getSvgPathProps(ctxt));
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createSvgTree('path', getSvgPathProps(ctxt));
  }

  Map<String, dynamic> getPathPoints() {
    final x1 = bounds.x;
    final x2 = bounds.right;
    final width = bounds.width;
    var y = bounds.y;
    var dy = bounds.height;
    if (isAbove) {
      y = bounds.bottom;
      dy = -dy;
    }
    final dx = width / 6;
    return <String, dynamic>{
      'x1': x1,
      'x2': x2,
      'y': y,
      'cx1': x1 + dx,
      'cx2': x2 - dx,
      'cy': y + dy,
    };
  }

  Map<String, dynamic> getSvgPathProps(ChantContext ctxt) {
    return <String, dynamic>{
      'd': generatePathString(),
      'stroke': ctxt.theme.neumeLineColor.toSvgString(),
      'stroke-width': '${ctxt.staffLineWeight}px',
      'fill': 'none',
      'class': 'brace',
    };
  }

  String generatePathString() {
    final points = getPathPoints();
    final dp = 2;
    return 'M ${points['x1'].toStringAsFixed(dp)} ${points['y'].toStringAsFixed(dp)} '
        'C ${points['cx1'].toStringAsFixed(dp)} ${points['cy'].toStringAsFixed(dp)} '
        '${points['cx2'].toStringAsFixed(dp)} ${points['cy'].toStringAsFixed(dp)} '
        '${points['x2'].toStringAsFixed(dp)} ${points['y'].toStringAsFixed(dp)}';
  }
}

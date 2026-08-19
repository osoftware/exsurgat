import 'dart:ui';

import 'package:xml/xml.dart';

import '../../chant_context.dart';
import '../../core.dart' as core;
import '../../drawing.dart';
import '../../glyphs.dart';
import '../../quick_svg.dart';
import '../chant_layout_element.dart';
import 'glyph_visualizer.dart';

class CurlyBraceVisualizer extends ChantLayoutElement {
  CurlyBraceVisualizer(
    ChantContext ctxt,
    double x1,
    double x2,
    double y,
    this.isAbove, [
    bool addAcuteAccent = false,
  ]) {
    ignoreBounds = true;
    if (x1 > x2) {
      final temp = x1;
      x1 = x2;
      x2 = temp;
    }
    braceHeight = ctxt.staffInterval / 2;
    if (isAbove) {
      y -= braceHeight;
    }
    final rect = core.Rect.fromXYWH(x1, y, x2 - x1, braceHeight);
    bounds = rect;
    origin = const core.Point(0, 0);
    if (addAcuteAccent && isAbove) {
      accent = GlyphVisualizer(ctxt, GlyphCode.acuteAccent, this)
        ..bounds = core.Rect.fromXYWH(
          rect.x + (x2 - x1) / 2,
          rect.y - ctxt.staffInterval / 4,
          accent!.bounds.width,
          accent!.bounds.height,
        );
    }
  }

  late bool isAbove;
  late double braceHeight;
  GlyphVisualizer? accent;

  @override
  void draw(ChantContext ctxt) {
    final points = getPathPoints();
    final path = Path()
      ..moveTo(points['x1'] as double, points['y'] as double)
      ..quadraticBezierTo(
        points['x1'] as double,
        points['qy1'] as double,
        points['qx2'] as double,
        points['qy2'] as double,
      )
      ..quadraticBezierTo(
        points['tx1'] as double,
        points['ty1'] as double,
        points['x2'] as double,
        points['y'] as double,
      );
    final paint = Paint()
      ..color = ctxt.theme.neumeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = ctxt.staffLineWeight;
    ctxt.canvas.drawPath(path, paint);
    if (accent != null) {
      accent!.draw(ctxt);
    }
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    final node = QuickSvg.createNode('path', getSvgPathProps(ctxt));
    if (accent != null) {
      return QuickSvg.createNode(
        'g',
        {'class': 'accentedBrace'},
        [node, accent!.createSvgNode(ctxt, source)],
      );
    }
    return node;
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    final node = QuickSvg.createSvgTree('path', getSvgPathProps(ctxt));
    if (accent != null) {
      return QuickSvg.createSvgTree(
        'g',
        {'class': 'accentedBrace'},
        [node, accent!.createSvgNode(ctxt, source)],
      );
    }
    return node;
  }

  Map<String, dynamic> getPathPoints() {
    final x1 = bounds.x;
    final x2 = bounds.right;
    final width = bounds.width;
    final y = isAbove ? bounds.bottom : bounds.y;
    final h = isAbove ? -braceHeight : braceHeight;
    final qy1 = y + 0.6 * h;
    final qx2 = x1 + 0.25 * width;
    final qy2 = y + (1 - 0.6) * h;
    final tx1 = x1 + 0.5 * width;
    final ty1 = y + h;
    return <String, dynamic>{
      'x1': x1,
      'x2': x2,
      'y': y,
      'qy1': qy1,
      'qx2': qx2,
      'qy2': qy2,
      'tx1': tx1,
      'ty1': ty1,
    };
  }

  Map<String, dynamic> getSvgPathProps(ChantContext ctxt) {
    return <String, dynamic>{
      'd': generatePathString(),
      'stroke': ctxt.theme.neumeColor.toSvgString(),
      'stroke-width': '${ctxt.staffLineWeight}px',
      'fill': 'none',
      'class': 'brace',
    };
  }

  String generatePathString() {
    final points = getPathPoints();
    final dp = 2;
    return 'M ${points['x1'].toStringAsFixed(dp)} ${points['y'].toStringAsFixed(dp)} '
        'Q ${points['x1'].toStringAsFixed(dp)} ${points['qy1'].toStringAsFixed(dp)} '
        '${points['qx2'].toStringAsFixed(dp)} ${points['qy2'].toStringAsFixed(dp)} '
        'T ${points['tx1'].toStringAsFixed(dp)} ${points['ty1'].toStringAsFixed(dp)} '
        'M ${points['x2'].toStringAsFixed(dp)} ${points['y'].toStringAsFixed(dp)} '
        'Q ${points['x2'].toStringAsFixed(dp)} ${points['qy1'].toStringAsFixed(dp)} '
        '${points['qx2'].toStringAsFixed(dp)} ${points['qy2'].toStringAsFixed(dp)} '
        'T ${points['tx1'].toStringAsFixed(dp)} ${points['ty1'].toStringAsFixed(dp)}';
  }
}

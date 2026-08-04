import 'dart:ui';

import 'package:xml/xml.dart';

import '../../chant_context.dart';
import '../../core.dart' as core;
import '../../drawing.dart';
import '../../quick_svg.dart';
import '../chant_layout_element.dart';

class NeumeBeamVisualizer extends ChantLayoutElement {
  NeumeBeamVisualizer(
    ChantContext ctxt,
    double x0,
    double x1,
    double staffPosition0,
    double staffPosition1, [
    double yOffset = 0,
  ]) {
    var y0 = ctxt.calculateHeightFromStaffPosition(staffPosition0.toInt());
    var y1 = ctxt.calculateHeightFromStaffPosition(staffPosition1.toInt());

    if (y0 == y1 && x0 == x1) {
      y0 -= ctxt.staffInterval / 2;
      x0 -= ctxt.staffInterval * 2 / 3;
    }

    bounds = core.Rect.fromXYWH(
      x0,
      y0 + (yOffset * ctxt.neumeLineWeight * 6),
      x1 - x0,
      y1 - y0,
    );
    origin = const core.Point(0, 0);
  }

  Map<String, dynamic> getPoints(ChantContext ctxt) {
    final lineHeight = ctxt.neumeLineWeight * 3;
    return <String, dynamic>{
      'x0': bounds.x - ctxt.neumeLineWeight / 2,
      'x1': bounds.x + bounds.width + ctxt.neumeLineWeight / 2,
      'y0': bounds.y,
      'y1': bounds.y + bounds.height,
      'height': lineHeight,
    };
  }

  @override
  void draw(ChantContext ctxt) {
    final points = getPoints(ctxt);
    final path = Path()
      ..moveTo(
        points['x0'] as double,
        (points['y0'] as double) + ((points['height'] as double) / 2),
      )
      ..lineTo(
        points['x0'] as double,
        (points['y0'] as double) - ((points['height'] as double) / 2),
      )
      ..lineTo(
        points['x1'] as double,
        (points['y1'] as double) - ((points['height'] as double) / 2),
      )
      ..lineTo(
        points['x1'] as double,
        (points['y1'] as double) + ((points['height'] as double) / 2),
      )
      ..close();
    final paint = Paint()..color = ctxt.theme.neumeLineColor;
    ctxt.canvas.drawPath(path, paint);
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createNode('polygon', getSvgProps(ctxt));
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createSvgTree('polygon', getSvgProps(ctxt));
  }

  Map<String, dynamic> getSvgProps(ChantContext ctxt) {
    final points = getPoints(ctxt);
    return <String, dynamic>{
      'points':
          '${points['x0']},${points['y0'] + points['height'] / 2} '
          '${points['x0']},${points['y0'] - points['height'] / 2} '
          '${points['x1']},${points['y1'] - points['height'] / 2} '
          '${points['x1']},${points['y1'] + points['height'] / 2}',
      'fill': ctxt.theme.neumeLineColor.toSvgString(),
      'class': 'neumeBeam',
    };
  }
}

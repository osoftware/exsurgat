import 'dart:ui';

import 'package:xml/xml.dart';

import '../../core.dart' as core;
import '../../drawing.dart' hide Rect;
import '../../quick_svg.dart';
import '../chant_layout_element.dart';
import '../notation/neumes/note.dart';

class VirgaLineVisualizer extends ChantLayoutElement {
  VirgaLineVisualizer(ChantContext ctxt, Note note) {
    final staffPosition = note.staffPosition;
    final y0 = ctxt.calculateHeightFromStaffPosition(staffPosition);
    final y1 = (staffPosition.abs() % 2) == 0
        ? y0 + ctxt.staffInterval * 1.8
        : y0 + ctxt.staffInterval * 2.7;

    bounds = core.Rect.fromXYWH(0, y0, ctxt.neumeLineWeight, y1 - y0);
    origin = const core.Point(0, 0);
  }

  @override
  void draw(ChantContext ctxt) {
    final paint = Paint()..color = ctxt.neumeLineColor;
    ctxt.canvas.drawRect(
      Rect.fromLTRB(
        bounds.x,
        bounds.y,
        bounds.x + ctxt.neumeLineWeight,
        bounds.y + bounds.height,
      ),
      paint,
    );
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createNode('rect', getSvgProps(ctxt));
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createSvgTree('rect', getSvgProps(ctxt));
  }

  @override
  String createSvgFragment(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createFragment('rect', getSvgProps(ctxt), null);
  }

  Map<String, dynamic> getSvgProps(ChantContext ctxt) {
    return <String, dynamic>{
      'x': bounds.x,
      'y': bounds.y,
      'width': ctxt.neumeLineWeight,
      'height': bounds.height,
      'fill': ctxt.neumeLineColor.toSvgString(),
      'class': 'neumeLine',
    };
  }
}

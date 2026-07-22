import 'dart:ui';

import 'package:xml/xml.dart';

import '../../core.dart' as core;
import '../../drawing.dart' hide Rect;
import '../../quick_svg.dart';
import '../chant_layout_element.dart';
import '../notation/neumes/note.dart';

class NeumeLineVisualizer extends ChantLayoutElement {
  NeumeLineVisualizer(
    ChantContext ctxt,
    Note note0,
    dynamic note1,
    bool hanging,
  ) {
    var staffPosition0 = note0.staffPosition;
    var staffPosition1 = switch (note1) {
      num p => p.toInt(),
      Note n => n.staffPosition,
      _ => note0.staffPosition + 4,
    };
    if (staffPosition0 < staffPosition1) {
      (staffPosition1, staffPosition0) = (staffPosition0, staffPosition1);
    }

    if (hanging && staffPosition0 - staffPosition1 > 4) {
      staffPosition1 = staffPosition0 - 4;
    }

    var y0 = ctxt.calculateHeightFromStaffPosition(staffPosition0);
    var y1 = 0.0;

    if (hanging) {
      if (staffPosition0 - staffPosition1 == 1 &&
          (staffPosition0.abs() % 2) == 1 &&
          staffPosition1 > -3) {
        staffPosition1--;
      }
      y1 += (ctxt.glyphPunctumHeight * ctxt.glyphScaling) / 2.2;
    }

    y1 += ctxt.calculateHeightFromStaffPosition(staffPosition1);

    bounds = core.Rect.fromXYWH(0, y0, ctxt.neumeLineWeight, y1 - y0);
    origin = const core.Point(0, 0);
  }

  @override
  void draw(ChantContext ctxt) {
    final paint = Paint()..color = ctxt.neumeLineColor;
    ctxt.canvasCtxt.drawRect(
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
      'fill': ctxt.neumeLineColor,
      'class': 'neumeLine',
    };
  }
}

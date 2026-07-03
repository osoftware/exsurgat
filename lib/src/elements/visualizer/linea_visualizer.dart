import 'dart:ui';

import 'package:xml/xml.dart';

import '../../core.dart' as core;
import '../../drawing.dart' hide Rect;
import '../../quick_svg.dart';
import '../chant_layout_element.dart';

class LineaVisualizer extends ChantLayoutElement {
  LineaVisualizer(ChantContext ctxt, dynamic note) {
    final staffPosition = note.staffPosition as int;
    final y0 =
        ctxt.calculateHeightFromStaffPosition(staffPosition) - note.origin.y;
    final y1 = y0 + note.bounds.height;

    bounds = core.Rect.fromXYWH(
      0,
      y0,
      ctxt.neumeLineWeight * 5 + note.bounds.width,
      y1 - y0,
    );
    origin = core.Point(ctxt.neumeLineWeight * 2.5, 0);
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
    ctxt.canvasCtxt.drawRect(
      Rect.fromLTRB(
        bounds.x + bounds.width - ctxt.neumeLineWeight,
        bounds.y,
        bounds.x + bounds.width,
        bounds.y + bounds.height,
      ),
      paint,
    );
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt) {
    final children = <XmlNode>[
      QuickSvg.createNode('rect', getSvgProps(ctxt, bounds.x)),
      QuickSvg.createNode(
        'rect',
        getSvgProps(ctxt, bounds.x + bounds.width - ctxt.neumeLineWeight),
      ),
    ];
    return QuickSvg.createNode('g', null, children);
  }

  @override
  String createSvgFragment(ChantContext ctxt) {
    final children = [
      QuickSvg.createFragment('rect', getSvgProps(ctxt, bounds.x), null),
      QuickSvg.createFragment(
        'rect',
        getSvgProps(ctxt, bounds.x + bounds.width - ctxt.neumeLineWeight),
        null,
      ),
    ].join();
    return QuickSvg.createFragment('g', {}, children);
  }

  Map<String, dynamic> getSvgProps(ChantContext ctxt, double x) {
    return <String, dynamic>{
      'x': x,
      'y': bounds.y,
      'width': ctxt.neumeLineWeight,
      'height': bounds.height,
      'fill': ctxt.neumeLineColor,
      'class': 'neumeLine',
    };
  }
}

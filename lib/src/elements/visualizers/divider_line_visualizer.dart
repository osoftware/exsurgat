import 'dart:math' as math;
import 'dart:ui';

import 'package:xml/xml.dart';

import '../../core.dart' as core;
import '../../drawing.dart' hide Rect;
import '../../quick_svg.dart';
import '../chant_layout_element.dart';

class DividerLineVisualizer extends ChantLayoutElement {
  DividerLineVisualizer(
    ChantContext ctxt,
    double staffPosition0,
    double staffPosition1, [
    this.divider,
  ]) {
    final y0 = ctxt.calculateHeightFromStaffPosition(staffPosition0);
    final y1 = ctxt.calculateHeightFromStaffPosition(staffPosition1);
    final top = math.min(y0, y1);
    final bottom = math.max(y0, y1);

    bounds = core.Rect.fromXYWH(0, top, ctxt.dividerLineWeight, bottom - top);
    origin = core.Point(bounds.width / 2, top);
  }

  late final dynamic divider;

  @override
  void draw(ChantContext ctxt) {
    final paint = Paint()..color = ctxt.dividerLineColor;
    final rect = Rect.fromLTWH(
      bounds.x,
      bounds.y,
      ctxt.dividerLineWeight,
      bounds.height,
    );
    ctxt.canvasCtxt.drawRect(rect, paint);
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt) {
    return QuickSvg.createNode('rect', getSvgProps(ctxt));
  }

  @override
  String createSvgFragment(ChantContext ctxt) {
    return QuickSvg.createFragment('rect', getSvgProps(ctxt), null);
  }

  Map<String, dynamic> getSvgProps(ChantContext ctxt) {
    final props = <String, dynamic>{
      'x': bounds.x,
      'y': bounds.y,
      'width': ctxt.dividerLineWeight,
      'height': bounds.height,
      'fill': ctxt.dividerLineColor,
      'class': 'dividerLine',
    };
    if (divider != null) {
      if (divider.selected == true) {
        props['class'] = '${props['class']} selected';
      }
      props['source-index'] = divider.sourceIndex;
      props['element-index'] = divider.elementIndex;
      props['source'] = divider;
    }
    return props;
  }
}

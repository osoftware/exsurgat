import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../core.dart' as core;
import '../drawing.dart';
import '../quick_svg.dart';
import 'chant_layout_element.dart';
import 'text/annotation.dart';

class Annotations extends ChantLayoutElement {
  Annotations(ChantContext ctxt, List<String> texts)
    : annotations = texts.map((text) => Annotation(ctxt, text, 0)).toList() {
    padding = annotations.map((a) => a.padding).fold(0, math.max);
  }

  double lineHeight = 1.1;
  List<Annotation> annotations = [];
  late double padding;

  void updateBounds([double multiplier = 1.0]) {
    for (var annotation in annotations) {
      annotation.bounds = core.Rect.fromXYWH(
        annotation.bounds.x + bounds.x * multiplier,
        annotation.bounds.y + bounds.y * multiplier,
        annotation.bounds.width,
        annotation.bounds.height,
      );
    }
  }

  void recalculateMetrics(ChantContext ctxt, [bool resetNewLines = true]) {
    bounds = core.Rect.fromXYWH(0, 0, 0, 0);
    origin = core.Point(0, 0);

    double y = 0;
    for (var a in annotations) {
      a.recalculateMetrics(ctxt, resetNewLines);
      bounds += core.Rect.fromXYWH(0, y, a.bounds.width, a.bounds.height);
      a.bounds = a.bounds.copyWith(y: a.bounds.y + y);
      origin = origin.copyWith(y: origin.y == 0 ? a.origin.y : origin.y);
      y += a.fontSize(ctxt) * (a.resize ?? 1) * lineHeight;
    }
  }

  @override
  void draw(ChantContext ctxt) {
    updateBounds();
    for (var annotation in annotations) {
      annotation.draw(ctxt);
    }
    updateBounds(-1.0);
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    updateBounds();
    final result = annotations
        .map((a) => a.createSvgNode(ctxt, source))
        .toList();
    updateBounds(-1.0);
    return QuickSvg.createNode('g', {}, result);
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    updateBounds();
    final result = annotations
        .map((a) => a.createSvgTree(ctxt, source))
        .toList();
    updateBounds(-1.0);
    return QuickSvg.createSvgTree('g', {}, result);
  }

  @override
  String createSvgFragment(ChantContext ctxt, [ChantLayoutElement? source]) {
    updateBounds();
    final result = annotations
        .map((a) => a.createSvgFragment(ctxt, source))
        .join('');
    updateBounds(-1.0);
    return result;
  }
}

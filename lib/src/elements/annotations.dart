import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../exsurgat.dart';
import '../core.dart' as core;
import '../drawing.dart';
import 'chant_layout_element.dart';
import 'text/annotation.dart';

class Annotations extends ChantLayoutElement {
  Annotations(ChantContext ctxt, List<String> texts)
    : lineHeight = 1.1,
      annotations = texts.map((text) => Annotation(ctxt, text, 0)).toList() {
    padding = annotations.isNotEmpty
        ? annotations.map((a) => a.padding).reduce(math.max)
        : 0;
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
    for (var annotation in annotations) {
      annotation.recalculateMetrics(ctxt, resetNewLines);
      bounds += core.Rect.fromXYWH(
        0,
        y,
        annotation.bounds.width,
        annotation.bounds.height,
      );
      annotation.bounds = core.Rect.fromXYWH(
        annotation.bounds.x,
        annotation.bounds.y + y,
        annotation.bounds.width,
        annotation.bounds.height,
      );
      origin = origin.y == 0 ? annotation.origin : origin;
      y += annotation.fontSize(ctxt) * (annotation.resize ?? 1) * lineHeight;
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

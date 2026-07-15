import 'package:xml/xml.dart';

import '../core.dart' as core;
import '../drawing.dart';
import '../quick_svg.dart';

abstract class ChantLayoutElement {
  ChantLayoutElement() {
    bounds = const core.Rect.fromXYWH(0, 0, 0, 0);
    origin = const core.Point(0, 0);

    selected = false;
    highlighted = false;
  }

  late core.Rect bounds;
  late core.Point origin;
  late bool selected;
  late bool highlighted;
  bool ignoreBounds = false;

  void draw(ChantContext ctxt);

  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]);

  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]);

  String createSvgFragment(ChantContext ctxt, [ChantLayoutElement? source]);
}

typedef ElementNodeMaker<T> = T Function(ChantLayoutElement e, ChantContext c);

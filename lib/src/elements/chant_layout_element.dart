import 'package:xml/xml.dart';

import '../chant_context.dart';
import '../core.dart';
import '../quick_svg.dart';

abstract class ChantLayoutElement {
  ChantLayoutElement() {
    bounds = const Rect.fromXYWH(0, 0, 0, 0);
    origin = const Point(0, 0);

    selected = false;
    highlighted = false;
  }

  late Rect bounds;
  late Point origin;
  late bool selected;
  late bool highlighted;
  bool ignoreBounds = false;

  void draw(ChantContext ctxt);

  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]);

  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]);
}

typedef ElementNodeMaker<T> = T Function(ChantLayoutElement e, ChantContext c);

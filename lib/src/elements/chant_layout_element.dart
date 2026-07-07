import 'package:xml/xml.dart';

import '../core.dart' as core;
import '../drawing.dart';

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

  XmlElement createSvgNode(ChantContext ctxt);

  String createSvgFragment(ChantContext ctxt);
}

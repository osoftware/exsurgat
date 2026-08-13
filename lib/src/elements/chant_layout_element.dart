import 'package:xml/xml.dart';

import '../chant_context.dart';
import '../core.dart';
import '../quick_svg.dart';

abstract class ChantLayoutElement {
  Rect bounds = const Rect.fromXYWH(0, 0, 0, 0);
  Point origin = const Point(0, 0);
  bool selected = false;
  bool highlighted = false;
  bool ignoreBounds = false;

  Rect get boundsForHitTest => bounds.copyWith(y: bounds.y - origin.y);

  void draw(ChantContext ctxt);

  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]);

  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]);
}

typedef ElementNodeMaker<T> = T Function(ChantLayoutElement e, ChantContext c);

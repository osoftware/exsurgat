/// @docImport '../chant_theme.dart';
/// @docImport '../chant_score.dart';
library;

import 'dart:ui';

import 'package:xml/xml.dart';

import '../chant_context.dart';
import '../core.dart';
import '../quick_svg.dart';

/// Base class for all elements in the score.
abstract class ChantLayoutElement {
  /// Relative bounds used to layout the element.
  Rect bounds = const Rect.fromXYWH(0, 0, 0, 0);

  /// Relative position used to layout the element.
  Point origin = const Point(0, 0);

  /// Whether the element should be highlighted as selected.
  ///
  /// Selection color is determined with [ChantTheme.selectionColor].
  /// Don't set directly, call [ChantScore.updateSelection].
  bool selected = false;

  /// Overrides the default color of this element.
  ///
  /// Takes precedence over color imposed with [selected].
  /// Can be used for hover, playback etc.
  /// Don't set directly, call [ChantScore.updateSelection].
  Color? highlight;

  /// Whether [bounds] of this element should affect bounds of the parent.
  bool ignoreBounds = false;

  /// Relative bounds where the element is hit-testable.
  ///
  /// Might be different than [bounds].
  Rect get boundsForHitTest => bounds.copyWith(y: bounds.y - origin.y);

  /// Paints this the element on [Canvas] attached to [ctxt].
  void draw(ChantContext ctxt);

  /// Generates SVG representation of the element.
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]);

  /// Generates a lightweight in-memory SVG-like tree.
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]);
}

typedef ElementNodeMaker<T> = T Function(ChantLayoutElement e, ChantContext c);

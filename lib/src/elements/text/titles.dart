import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../chant_context.dart';
import '../../chant_score.dart';
import '../../core.dart' as core;
import '../../quick_svg.dart';
import '../chant_layout_element.dart';
import '../text.dart';

export '../text/subtitle.dart';
export '../text/supertitle.dart';
export '../text/text_left_right.dart';
export '../text/title.dart';

/// Lays out and renders the title elements of a [ChantScore]: the supertitle,
/// title, subtitle, and left/right text.
class Titles extends ChantLayoutElement {
  Titles(
    ChantContext ctxt,
    this.score, {
    String? supertitle,
    String? title,
    String? subtitle,
    String? textLeft,
    String? textRight,
  }) {
    setSupertitle(ctxt, supertitle);
    setTitle(ctxt, title);
    setSubtitle(ctxt, subtitle);
    setTextLeft(ctxt, textLeft);
    setTextRight(ctxt, textRight);
  }

  /// The score that this [Titles] instance belongs to.
  ChantScore score;

  Supertitle? supertitle;
  Title? title;
  Subtitle? subtitle;
  TextLeftRight? textLeft;
  TextLeftRight? textRight;

  void setBoundsX(ChantContext ctxt, String elementName, double width) {
    final element = this[elementName];
    if (element == null) return;
    final style = ctxt.textStyles[elementName];
    final alignment = style?['alignment'];
    switch (alignment) {
      case 'left':
        element.textAnchor = .start;
        element.bounds = element.bounds.copyWith(x: 0);
        break;
      case 'right':
        element.textAnchor = .end;
        element.bounds = element.bounds.copyWith(x: width);
        break;
      case 'center':
      default:
        element.textAnchor = .center;
        element.bounds = element.bounds.copyWith(x: width / 2);
    }
  }

  /// Lays out the titles, and returns their total height.
  ///
  /// Returns the total height of titles laid out.
  double layoutTitles(ChantContext ctxt, double width) {
    bounds = const core.Rect.fromXYWH(0, 0, 0, 0);
    double y = 0;
    if (supertitle != null) {
      supertitle!.recalculateMetrics(ctxt);
      supertitle!.setMaxWidth(ctxt, width);

      setBoundsX(ctxt, 'supertitle', width);
      supertitle!.bounds = supertitle!.bounds.copyWith(y: y);
      bounds += supertitle!.bounds;
      supertitle!.bounds = supertitle!.bounds.copyWith(
        y: supertitle!.bounds.y + supertitle!.origin.y,
      );
      y += supertitle!.bounds.height + supertitle!.padding(ctxt);
    }
    if (title != null) {
      if (y != 0) y += title!.padding(ctxt);
      title!.recalculateMetrics(ctxt);
      title!.setMaxWidth(ctxt, width);
      setBoundsX(ctxt, 'title', width);
      title!.bounds = title!.bounds.copyWith(y: y);
      bounds += title!.bounds;
      title!.bounds = title!.bounds.copyWith(
        y: title!.bounds.y + title!.origin.y,
      );
      y += title!.bounds.height + title!.padding(ctxt);
    }
    if (subtitle != null) {
      if (y != 0) y += subtitle!.padding(ctxt);
      subtitle!.recalculateMetrics(ctxt);
      subtitle!.setMaxWidth(ctxt, width);
      setBoundsX(ctxt, 'subtitle', width);
      subtitle!.bounds = subtitle!.bounds.copyWith(y: y);
      bounds += subtitle!.bounds;
      subtitle!.bounds = subtitle!.bounds.copyWith(
        y: subtitle!.bounds.y + subtitle!.origin.y,
      );
      y += subtitle!.bounds.height + subtitle!.padding(ctxt);
    }
    double finalY = y;
    final textLeft = score.overrideTextLeft ?? this.textLeft;
    if (textLeft != null) {
      textLeft.recalculateMetrics(ctxt);
      textLeft.bounds = textLeft.bounds.copyWith(y: y);
      bounds += textLeft.bounds;
      textLeft.bounds = textLeft.bounds.copyWith(
        y: textLeft.bounds.y + textLeft.origin.y,
      );
      finalY = y + textLeft.bounds.height + textLeft.padding(ctxt);
    }
    if (textRight != null) {
      textRight!.recalculateMetrics(ctxt);
      textRight!.bounds = textRight!.bounds.copyWith(x: width, y: y);
      bounds += textRight!.bounds;
      textRight!.bounds = textRight!.bounds.copyWith(
        y: textRight!.bounds.y + textRight!.origin.y,
      );
      finalY = math.max(
        finalY,
        y + textRight!.bounds.height + textRight!.padding(ctxt),
      );
    }
    return finalY;
  }

  void setSupertitle(ChantContext ctxt, String? supertitle) {
    this.supertitle = supertitle != null ? Supertitle(ctxt, supertitle) : null;
  }

  void setTitle(ChantContext ctxt, String? title) {
    this.title = title != null ? Title(ctxt, title) : null;
  }

  void setSubtitle(ChantContext ctxt, String? subtitle) {
    this.subtitle = subtitle != null ? Subtitle(ctxt, subtitle) : null;
  }

  void setTextLeft(ChantContext ctxt, String? textLeft) {
    this.textLeft = textLeft != null
        ? TextLeftRight(ctxt, textLeft, 'textLeft')
        : null;
  }

  void setTextRight(ChantContext ctxt, String? textRight) {
    this.textRight = textRight != null
        ? TextLeftRight(ctxt, textRight, 'textRight')
        : null;
  }

  bool hasSupertitle(ChantContext ctxt, String? supertitle) =>
      this.supertitle != null;
  bool hasTitle(ChantContext ctxt, String? title) => this.title != null;
  bool hasSubtitle(ChantContext ctxt, String? subtitle) =>
      this.subtitle != null;
  bool hasTextLeft(ChantContext ctxt, String? textLeft) =>
      this.textLeft != null;
  bool hasTextRight(ChantContext ctxt, String? textRight) =>
      this.textRight != null;

  List<TitleTextElement> get elements {
    return [
      ?supertitle,
      ?title,
      ?subtitle,
      ?score.overrideTextLeft ?? textLeft,
      ?textRight,
    ];
  }

  @override
  void draw(ChantContext ctxt, [double scale = 1]) {
    final canvasCtxt = ctxt.canvas;
    canvasCtxt.translate(bounds.x, bounds.y);

    for (final el in elements) {
      el.draw(ctxt);
    }

    canvasCtxt.translate(-bounds.x, -bounds.y);
  }

  List<T> getInnerNodes<T>(ChantContext ctxt, ElementNodeMaker<T> create) {
    return [for (final el in elements) create(el, ctxt)];
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    final titles = getInnerNodes(ctxt, (e, c) => e.createSvgNode(c, source));
    return QuickSvg.createNode('g', {'class': 'Titles'}, titles);
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    final titles = getInnerNodes(ctxt, (e, c) => e.createSvgTree(c, source));
    return QuickSvg.createSvgTree('g', {'class': 'Titles'}, titles);
  }

  /// Indexer that allows accessing the title elements by name, mirroring the
  /// JavaScript implementation which uses `this[elementName]`.
  TitleTextElement? operator [](String elementName) {
    switch (elementName) {
      case 'supertitle':
        return supertitle;
      case 'title':
        return title;
      case 'subtitle':
        return subtitle;
      case 'textLeft':
        return textLeft;
      case 'textRight':
        return textRight;
      default:
        return null;
    }
  }
}

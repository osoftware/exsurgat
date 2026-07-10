import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../core.dart' as core;
import '../../drawing.dart';
import '../../quick_svg.dart';
import '../chant_layout_element.dart';
import '../text/above_lines_text.dart';
import '../text/lyric.dart';
import '../text/translation_text.dart';

const double kDefaultTrailingSpace = 0.0;

class ChantNotationElement extends ChantLayoutElement {
  ChantNotationElement() {
    leadingSpace = 0.0;
    trailingSpace = kDefaultTrailingSpace;
  }

  double leadingSpace = 0.0;
  double trailingSpace = kDefaultTrailingSpace;
  double calculatedTrailingSpace = 0;
  bool keepWithNext = false;
  bool needsLayout = true;
  bool allowLineBreakBeforeNext = false;
  int? sourceIndex;
  String sourceGabc = '';
  int sourceLength = 0;
  bool? firstOfSyllable;
  bool? firstOfParentheses;
  List<Lyric> lyrics = [];
  dynamic score;
  dynamic line;
  dynamic mapping;
  int notationIndex = 0;
  int? elementIndex;
  final List<ChantLayoutElement> visualizers = <ChantLayoutElement>[];
  List<AboveLinesText> alText = [];
  List<TranslationText> translationText = [];
  dynamic cssClass;

  bool hasNoWidth = false;

  ChantNotationElement? firstWithNoWidth;

  bool hasLyrics() => lyrics.isNotEmpty;

  double getAllLyricsLeft() {
    if (lyrics.isEmpty) return bounds.right;
    var x = double.maxFinite;
    for (final lyric in lyrics) {
      x = math.min(x, lyric.bounds.x);
    }
    return bounds.x + x;
  }

  double getAllLyricsRight() {
    if (lyrics.isEmpty) return bounds.x;
    var x = -double.maxFinite;
    for (final lyric in lyrics) {
      x = math.max(x, lyric.bounds.x + lyric.bounds.width);
    }
    return bounds.x + x;
  }

  void addVisualizer(ChantLayoutElement chantLayoutElement) {
    if (!chantLayoutElement.ignoreBounds) {
      if (bounds.x == 0 &&
          bounds.y == 0 &&
          bounds.width == 0 &&
          bounds.height == 0) {
        bounds = chantLayoutElement.bounds.clone();
      } else {
        bounds += chantLayoutElement.bounds;
      }
    }
    visualizers.add(chantLayoutElement);
  }

  void prependVisualizer(ChantLayoutElement chantLayoutElement) {
    if (!chantLayoutElement.ignoreBounds) {
      if (bounds.x == 0 &&
          bounds.y == 0 &&
          bounds.width == 0 &&
          bounds.height == 0) {
        bounds = chantLayoutElement.bounds.clone();
      } else {
        bounds += chantLayoutElement.bounds;
      }
    }
    visualizers.insert(0, chantLayoutElement);
  }

  void performLayout(ChantContext ctxt) {
    visualizers.clear();
    bounds = const core.Rect.fromXYWH(0, 0, 0, 0);
    for (final lyric in lyrics) {
      lyric.recalculateMetrics(ctxt);
    }
  }

  void finishLayout(ChantContext ctxt) {
    bounds = core.Rect.fromXYWH(0, 0, bounds.width, bounds.height);
    needsLayout = false;
  }

  @override
  void draw(ChantContext ctxt) {
    ctxt.canvasCtxt.save();
    ctxt.canvasCtxt.translate(bounds.x, 0);
    for (final visualizer in visualizers) {
      visualizer.draw(ctxt);
    }
    ctxt.canvasCtxt.restore();
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt) => QuickSvg.createNode(
    'g',
    getSvgProps(),
    visualizers.map((v) => v.createSvgNode(ctxt)),
  );

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt) => QuickSvg.createSvgTree(
    'g',
    getSvgProps(),
    visualizers.map((v) => v.createSvgTree(ctxt)),
  );

  @override
  String createSvgFragment(ChantContext ctxt) {
    return QuickSvg.createFragment(
      'g',
      getSvgProps(),
      visualizers.map((v) => v.createSvgFragment(ctxt)).join(),
    );
  }

  Map<String, dynamic> getSvgProps() {
    return <String, dynamic>{
      'class': 'ChantNotationElement ${cssClass ?? runtimeType}',
      'transform': 'translate(${bounds.x},0)',
    };
  }
}

import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../chant_context.dart';
import '../../chant_mapping.dart';
import '../../chant_score.dart';
import '../../core.dart';
import '../../quick_svg.dart';
import '../../trailing_space.dart';
import '../chant_layout_element.dart';
import '../chant_line.dart';
import '../text/above_lines_text.dart';
import '../text/lyric.dart';
import '../text/translation_text.dart';

class ChantNotationElement extends ChantLayoutElement {
  double leadingSpace = 0.0;
  TrailingSpace trailingSpace = TrailingSpace.defaultTrailingSpace;
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
  late ChantScore score;
  late ChantLine line;
  late ChantMapping mapping;
  int notationIndex = 0;
  int? elementIndex;
  final List<ChantLayoutElement> visualizers = [];
  List<AboveLinesText> alText = [];
  List<TranslationText> translationText = [];
  String? cssClass;

  bool hasNoWidth = false;

  ChantNotationElement? firstWithNoWidth;

  bool get hasLyrics => lyrics.isNotEmpty;

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
      if (bounds.isEmpty) {
        bounds = chantLayoutElement.bounds.clone();
      } else {
        bounds += chantLayoutElement.bounds;
      }
    }
    visualizers.add(chantLayoutElement);
  }

  void prependVisualizer(ChantLayoutElement chantLayoutElement) {
    if (bounds.isEmpty) {
      bounds = chantLayoutElement.bounds.clone();
    } else {
      bounds += chantLayoutElement.bounds;
    }

    visualizers.insert(0, chantLayoutElement);
  }

  void performLayout(ChantContext ctxt) {
    calculatedTrailingSpace = trailingSpace(ctxt);

    visualizers.clear();
    bounds = const Rect();
    for (final l in lyrics) {
      l.recalculateMetrics(ctxt);
    }
    for (final al in alText) {
      al.recalculateMetrics(ctxt);
    }
    for (final t in translationText) {
      t.recalculateMetrics(ctxt);
    }
  }

  void finishLayout(ChantContext ctxt) {
    bounds = bounds.copyWith(x: 0);

    final language =
        lyrics.elementAtOrNull(0)?.language ?? ctxt.defaultLanguage;

    final calculateLyricX = language.centerNeume
        ? (Lyric l) {
            final offset = ctxt.staffInterval < l.vowelSegmentWidth
                ? bounds.width / 2 - l.origin.x
                : origin.x - l.origin.x;
            l.bounds = l.bounds.copyWith(x: bounds.width + offset);
          }
        : (Lyric l) {
            l.bounds = l.bounds.copyWith(x: origin.x - l.origin.x);
          };
    lyrics.forEach(calculateLyricX);

    needsLayout = false;
  }

  @override
  void draw(ChantContext ctxt) {
    ctxt.canvas.save();
    ctxt.canvas.translate(bounds.x, 0);
    for (final visualizer in visualizers) {
      visualizer.draw(ctxt);
    }

    for (final text in [...lyrics, ...translationText, ...alText]) {
      text.draw(ctxt);
    }

    ctxt.canvas.restore();
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) =>
      QuickSvg.createNode('g', getSvgProps(), [
        for (final l in lyrics) l.createSvgNode(ctxt),
        for (final t in translationText) t.createSvgNode(ctxt),
        for (final al in alText) al.createSvgNode(ctxt),
        QuickSvg.createNode(
          'g',
          {'class': 'Notation'},
          [for (final v in visualizers) v.createSvgNode(ctxt, this)],
        ),
      ]);

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) =>
      QuickSvg.createSvgTree('g', getSvgProps(), [
        for (final l in lyrics) l.createSvgTree(ctxt),
        for (final t in translationText) t.createSvgTree(ctxt),
        for (final al in alText) al.createSvgTree(ctxt),
        QuickSvg.createSvgTree(
          'g',
          {'class': 'Notation'},
          [for (final v in visualizers) v.createSvgTree(ctxt, this)],
        ),
      ]);

  Map<String, dynamic> getSvgProps() {
    return <String, dynamic>{
      'class': 'ChantNotationElement ${cssClass ?? runtimeType}',
      'transform': 'translate(${bounds.x},0)',
    };
  }

  String toGabcString() {
    final buf = StringBuffer();
    buf.write(lyrics.map((l) => l.toGabcString()).join('|'));
    buf.write(translationText.map((t) => t.toGabcString()).join(('')));
    buf.write(alText.map((al) => al.toGabcString()).join(''));
    return buf.toString();
  }
}

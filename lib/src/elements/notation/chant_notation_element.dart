import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../core.dart' as core;
import '../../drawing.dart';
import '../../quick_svg.dart';
import '../chant_layout_element.dart';

const double kDefaultTrailingSpace = 0.0;

class ChantNotationElement extends ChantLayoutElement {
  ChantNotationElement() {
    leadingSpace = 0.0;
    trailingSpace = kDefaultTrailingSpace;
    keepWithNext = false;
    needsLayout = true;
    lyrics = <dynamic>[];
    visualizers = <ChantLayoutElement>[];
    alText = <dynamic>[];
    translationText = <dynamic>[];
  }

  double leadingSpace = 0.0;
  double trailingSpace = kDefaultTrailingSpace;
  bool keepWithNext = false;
  bool needsLayout = true;
  List<dynamic> lyrics = <dynamic>[];
  dynamic score;
  dynamic line;
  List<ChantLayoutElement> visualizers = <ChantLayoutElement>[];
  List<dynamic> alText = <dynamic>[];
  List<dynamic> translationText = <dynamic>[];
  dynamic cssClass;
  bool isNeume = false;
  bool hasNoWidth = false;

  bool hasLyrics() => lyrics.isNotEmpty;

  double getAllLyricsLeft() {
    if (lyrics.isEmpty) return bounds.right;
    var x = double.maxFinite;
    for (final lyric in lyrics) {
      if (lyric != null) {
        x = math.min(x, lyric.bounds.x);
      }
    }
    return bounds.x + x;
  }

  double getAllLyricsRight() {
    if (lyrics.isEmpty) return bounds.x;
    var x = -double.maxFinite;
    for (final lyric in lyrics) {
      if (lyric != null) {
        x = math.max(x, lyric.bounds.x + lyric.bounds.width);
      }
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
        bounds = bounds.union(chantLayoutElement.bounds);
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
        bounds = bounds.union(chantLayoutElement.bounds);
      }
    }
    visualizers.insert(0, chantLayoutElement);
  }

  void performLayout(ChantContext ctxt) {
    visualizers = <ChantLayoutElement>[];
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
  XmlElement createSvgNode(ChantContext ctxt) {
    final inner = <XmlNode>[];
    for (final visualizer in visualizers) {
      inner.add(visualizer.createSvgNode(ctxt));
    }
    return QuickSvg.createNode('g', getSvgProps(), inner);
  }

  @override
  String createSvgFragment(ChantContext ctxt) {
    final inner = visualizers
        .map((visualizer) => visualizer.createSvgFragment(ctxt))
        .join();
    return QuickSvg.createFragment('g', getSvgProps(), inner);
  }

  Map<String, dynamic> getSvgProps() {
    return <String, dynamic>{
      'class': 'ChantNotationElement ${cssClass ?? runtimeType}',
      'transform': 'translate(${bounds.x},0)',
    };
  }
}

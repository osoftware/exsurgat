import 'dart:math' as math;

import '../../core.dart' as core;
import '../../drawing.dart';
import '../../language.dart';
import '../notation/chant_notation_element.dart';
import 'drop_cap.dart';
import 'text_element.dart';

enum LyricType {
  singleSyllable,
  beginningSyllable,
  middleSyllable,
  endingSyllable,
  directive,
}

class LyricArray {
  static double getLeft(List<dynamic> lyricArray) {
    if (lyricArray.isEmpty) return double.nan;
    var x = double.maxFinite;
    for (final lyric in lyricArray) {
      if (lyric != null) {
        x = math.min(x, lyric.notation.bounds.x + lyric.bounds.x);
      }
    }
    return x;
  }

  static double getRight(
    List<Lyric> lyricArray, [
    bool presumeConnectorNeeded = false,
  ]) {
    if (lyricArray.isEmpty) return double.nan;
    var x = -double.maxFinite;
    for (final lyric in lyricArray) {
      x = math.max(
        x,
        lyric.notation!.bounds.x +
            lyric.bounds.x +
            lyric.bounds.width +
            (presumeConnectorNeeded &&
                    lyric.allowsConnector &&
                    !lyric.needsConnector
                ? lyric.getConnectorWidth()
                : 0),
      );
    }
    return x;
  }

  static bool hasOnlyOneLyric(List<Lyric> lyricArray) {
    return lyricArray.where((l) => l.originalText.isNotEmpty).length == 1;
  }

  static int indexOfLyric(List<Lyric> lyricArray) {
    final filtered = lyricArray
        .where((l) => l.originalText.isNotEmpty)
        .toList();
    return filtered.isNotEmpty ? lyricArray.indexOf(filtered[0]) : -1;
  }

  static void mergeIn(List<Lyric> lyricArray, List<Lyric> newLyrics) {
    for (var i = 0; i < newLyrics.length; ++i) {
      if (newLyrics[i].originalText.isNotEmpty) {
        if (lyricArray.length <= i) {
          lyricArray.add(newLyrics[i]);
        } else {
          lyricArray[i] = newLyrics[i];
        }
      }
    }
  }

  static void mergeInArray(
    List<Lyric> lyricArray,
    List<ChantNotationElement> notations,
  ) {
    for (var i = 0; i < notations.length; ++i) {
      mergeIn(lyricArray, notations[i].lyrics);
    }
  }

  static void setNotation(List<dynamic> lyricArray, dynamic notation) {
    notation.lyrics = lyricArray;
    for (var i = 0; i < lyricArray.length; ++i) {
      lyricArray[i].notation = notation;
    }
  }
}

class Lyric extends TextElement {
  static RegExp letter = RegExp(
    r'[a-záéíóúýäëïöüÿàèìòùỳāēīōūȳăĕĭŏŭ]',
    caseSensitive: false,
  );

  Lyric(
    ChantContext ctxt,
    String text,
    this.lyricType, [
    this.notation,
    this.notations,
    int sourceIndex = 0,
  ]) : super(
         ctxt,
         (ctxt.textStyles['lyric']?['prefix'] ?? '') + text,
         (ctxt) => ctxt.textStyles['lyric']?['font'],
         (ctxt) => ctxt.textStyles['lyric']?['size'],
         'start',
         sourceIndex,
         text,
       ) {
    textType = TextTypes['lyric']!;
    originalText = text;
    centerStartIndex = -1;
    centerLength = text.length;
    needsConnector = false;
    language = null;
    if (allowsConnector) {
      connectorSpan = TextSpan(ctxt.syllableConnector, [], []);
    }
  }

  final ChantNotationElement? notation;
  final List<ChantNotationElement>? notations;
  late LyricType lyricType;
  late String originalText;
  int centerStartIndex = -1;
  int centerLength = 0;
  bool needsConnector = false;
  bool elidesToNext = false;
  double widthWithoutConnector = 0;
  double vowelSegmentWidth = 0;
  double? connectorWidth;
  double? defaultConnectorWidth;
  Language? language;

  double? lineWidth;

  bool get allowsConnector =>
      lyricType == LyricType.beginningSyllable ||
      lyricType == LyricType.middleSyllable;

  void setForceConnector(bool force) {
    forceConnector = force && allowsConnector;
  }

  void setNeedsConnector([bool needs = false, double? width]) {
    if (needs || (forceConnector ?? false)) {
      needsConnector = true;
      if (width != null) {
        setConnectorWidth(width);
      } else {
        bounds = core.Rect.fromXYWH(
          bounds.x,
          bounds.y,
          widthWithoutConnector + getConnectorWidth(),
          bounds.height,
        );
      }
      if (spans.isNotEmpty && spans.last != connectorSpan) {
        spans.add(connectorSpan!);
      }
    } else {
      connectorWidth = 0;
      needsConnector = false;
      bounds = core.Rect.fromXYWH(
        bounds.x,
        bounds.y,
        widthWithoutConnector,
        bounds.height,
      );
      final span = spans.isNotEmpty ? spans.removeLast() : null;
      if (span != null && span != connectorSpan) {
        spans.add(span);
      }
    }
  }

  void setConnectorWidth(double width) {
    connectorWidth = width;
    connectorSpan?.properties['textLength'] = width;
    if (needsConnector) {
      bounds = core.Rect.fromXYWH(
        bounds.x,
        bounds.y,
        widthWithoutConnector + getConnectorWidth(),
        bounds.height,
      );
    }
  }

  double getConnectorWidth() => connectorWidth ?? defaultConnectorWidth ?? 0;

  double getLeft() => notation!.bounds.x + bounds.x;

  double getRight() => notation!.bounds.x + bounds.x + bounds.width;

  @override
  void recalculateMetrics(ChantContext ctxt, [bool resetNewLines = true]) {
    setNeedsConnector();
    super.recalculateMetrics(ctxt, resetNewLines);
    widthWithoutConnector = bounds.width;
    connectorWidth = 0;
    defaultConnectorWidth = ctxt.hyphenWidth;

    final activeLanguage = language ?? ctxt.defaultLanguage;
    var offset = widthWithoutConnector / 2;

    if (centerStartIndex >= 0 &&
        (centerStartIndex >= text.length ||
            centerLength < 0 ||
            centerStartIndex + centerLength > text.length)) {
      centerStartIndex = -1;
    }

    if (text.isEmpty) {
      if (dropCap != null && originalText.isNotEmpty) {
        offset = ctxt.hyphenWidth / 2;
        vowelSegmentWidth = ctxt.hyphenWidth;
      }
    } else if (centerStartIndex >= 0) {
      final x1 = ctxt.textMeasurer.getSubstringWidth(
        this,
        ctxt,
        0,
        centerStartIndex,
      );
      final x2 = ctxt.textMeasurer.getSubstringWidth(
        this,
        ctxt,
        0,
        centerStartIndex + centerLength,
      );
      offset = (x1 + x2) / 2;
      vowelSegmentWidth = x2 - x1;
    } else {
      if (lyricType != LyricType.directive) {
        var startIndex = text.lastIndexOf(' ') + 1;

        if (startIndex > 0 && !letter.hasMatch(text.substring(startIndex))) {
          startIndex = 0;
        }

        final ignore = <Map<String, int>>[];
        var index = 0;
        final indexOffset = startIndex;
        for (final span in spans) {
          final endIndex = index + span.text.length;
          if (span.activeTags.contains('e')) {
            if (index <= startIndex) {
              startIndex = endIndex;
            } else {
              ignore.add({
                'index': index - indexOffset,
                'endIndex': endIndex - indexOffset,
              });
            }
          }
          index = endIndex;
        }

        final result = activeLanguage.findVowelSegment(
          text,
          startIndex,
          ignore,
        );
        var start = result.startIndex;
        var length = result.length;
        if (!result.found) {
          final match = RegExp(
            r'[a-z]+',
            caseSensitive: false,
          ).firstMatch(text.substring(startIndex));
          if (match != null) {
            start = startIndex + match.start;
            length = match.group(0)!.length;
          } else {
            start = startIndex;
            length = text.length - startIndex;
          }
        }

        final x1 = ctxt.textMeasurer.getSubstringWidth(this, ctxt, 0, start);
        final x2 = ctxt.textMeasurer.getSubstringWidth(
          this,
          ctxt,
          0,
          start + length,
        );
        offset = (x1 + x2) / 2;
        vowelSegmentWidth = x2 - x1;
      }
    }

    bounds = core.Rect.fromXYWH(-offset, 0, bounds.width, bounds.height);
    origin = core.Point(offset, origin.y);
  }

  DropCap? generateDropCap(ChantContext ctxt) {
    if (dropCap != null) return dropCap;
    if (spans.isEmpty ||
        spans[0].properties['font-family'] ==
            ctxt.specialCharProperties['font-family']) {
      return null;
    }

    final dropCapSpan = spans[0].clone();
    dropCapSpan.text = dropCapSpan.text.substring(0, 1).toUpperCase();
    final dropCapLowerCase = dropCapSpan.text.toLowerCase();
    if (dropCapSpan.text == dropCapLowerCase) return null;
    if (dropCapSpan.activeTags.contains('sc')) {
      dropCapSpan.text = dropCapLowerCase;
    }

    final generatedDropCap = DropCap(ctxt, '', sourceIndex);
    generatedDropCap.spans = [dropCapSpan];
    final match = RegExp(
      r'^(?:<\/?[^>]+>)*.?(?:<\/[^>]+>)*',
    ).firstMatch(sourceGabc);
    final dropCapSourceGabcLength = match?.group(0)?.length ?? 0;
    generatedDropCap.sourceGabc = sourceGabc.substring(
      0,
      dropCapSourceGabcLength,
    );
    sourceIndex += generatedDropCap.sourceGabc.length;
    sourceGabc = sourceGabc.substring(dropCapSourceGabcLength);

    spans[0].text = spans[0].text.substring(1);
    text = text.substring(1);
    centerStartIndex -= 1;

    return generatedDropCap;
  }

  @override
  String getCssClasses() {
    final classes = lyricType == LyricType.directive ? 'directive ' : '';
    return classes + super.getCssClasses();
  }

  @override
  Map<String, dynamic> getExtraStyleProperties(ChantContext ctxt) {
    final props = Map<String, dynamic>.from(
      super.getExtraStyleProperties(ctxt),
    );
    if (lyricType == LyricType.directive && ctxt.autoColor) {
      props['fill'] = ctxt.rubricColor;
    }
    return props;
  }
}

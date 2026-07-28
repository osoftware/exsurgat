import 'dart:ui' as ui;

import 'drawing.dart';
import 'elements/text/text_element.dart';

enum TextMeasuringStrategy { svg, canvas }

abstract class TextMeasurer {
  const TextMeasurer();

  factory TextMeasurer.create(TextMeasuringStrategy strategy) {
    return switch (strategy) {
      TextMeasuringStrategy.canvas => CanvasTextMeasurerStrategy(),
      TextMeasuringStrategy.svg => SvgTextMeasurerStrategy(),
    };
  }

  double measureSubstring(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
  ]) {
    if (length == 0) return 0;
    return measureTextBounds(textElement, ctxt, length).width;
  }

  Rect measureTextBounds(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
  ]);

  double getSubstringWidth(
    TextElement textElement,
    ChantContext ctxt, [
    int? startIndex,
    int? endIndex,
  ]) {
    if (endIndex == null) {
      endIndex = startIndex;
      startIndex = 0;
    }
    if (endIndex != null && endIndex <= (startIndex ?? 0)) return 0;

    final from = measureSubstring(textElement, ctxt, endIndex ?? 0);
    final to = measureSubstring(textElement, ctxt, startIndex ?? 0);
    return from - to;
  }

  void recalculateMetrics(
    TextElement textElement,
    ChantContext ctxt, [
    bool resetNewLines = true,
  ]) {
    if (resetNewLines) {
      // TODO: inspect what to reset
      textElement.setMaxWidth(ctxt, double.infinity);
      for (final span in textElement.spans) {
        span.xOffset = null;
        if (span.newLine != null) {
          span.newLine = null;
          span.text = " ${span.text}"; // TODO: WTF
        }
      }
    }

    textElement.bounds = textElement.bounds.copyWith(x: 0, y: 0);
    textElement.origin = Point(0, textElement.origin.y);

    final bbox = measureTextBounds(textElement, ctxt);
    textElement.bounds = textElement.bounds.copyWith(
      width: bbox.width,
      height: bbox.height,
    );
    textElement.origin = Point(-bbox.x, -bbox.y);

    textElement.numLines = textElement.spans.fold(
      1,
      (acc, s) => acc + (s.newLine ?? 0),
    );
  }
}

final class CanvasTextMeasurerStrategy extends TextMeasurer {
  @override
  Rect measureTextBounds(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
  ]) {
    if (length == 0) return Rect.fromXYWH(0, 0, 0, 0);

    int consumed = 0;
    Rect? box;
    Rect cur = Rect.fromXYWH(0, 0, 0, 0);
    Rect prev;

    for (final span in textElement.spans) {
      prev = cur;
      final t = span.text.substring(
        0,
        length == null ? null : length - consumed,
      );
      final props = {
        ...textElement.getExtraStyleProperties(ctxt),
        ...span.properties,
        'base-font-family': textElement.fontFamily(ctxt),
        'base-font-size': textElement.fontSize(ctxt),
      };
      final p = _buildParagraph(ctxt, t, props, textElement.resize);

      late final double width, height;
      if (p.numberOfLines > 0) {
        final metrics = p.getLineMetricsAt(0)!;
        width = metrics.width;
        height = metrics.height + metrics.descent;
      } else {
        width = p.maxIntrinsicWidth;
        height = p.height;
      }

      cur = span.newLine != null
          ? Rect.fromXYWH(0, prev.bottom, width, height)
          : Rect.fromXYWH(prev.right, prev.y > 0 ? prev.y : 0, width, height);
      box = box != null ? box + cur : cur;

      consumed += t.length;
      if (consumed == length) break;
    }

    return box ?? cur;
  }
}

final class SvgTextMeasurerStrategy extends TextMeasurer {
  @override
  Rect measureTextBounds(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
  ]) {
    if (length == 0) return Rect.fromXYWH(0, 0, 0, 0);

    int consumed = 0;
    Rect? box;
    Rect cur = Rect.fromXYWH(0, 0, 0, 0);
    Rect prev;

    for (final span in textElement.spans) {
      prev = cur;
      final t = span.text.substring(
        0,
        length == null ? null : length - consumed,
      );
      final props = {
        ...textElement.getExtraStyleProperties(ctxt),
        ...span.properties,
        'base-font-family': textElement.fontFamily(ctxt),
        'base-font-size': textElement.fontSize(ctxt),
      };
      final p = _buildParagraph(ctxt, t, props, textElement.resize);

      late final double width, height, baseline;
      if (p.numberOfLines > 0) {
        final metrics = p.getLineMetricsAt(0)!;
        width = metrics.width;
        height = metrics.height + metrics.descent;
        baseline = metrics.baseline;
      } else {
        width = p.maxIntrinsicWidth;
        height = p.height;
        baseline = p.alphabeticBaseline;
      }

      cur = span.newLine != null
          ? Rect.fromXYWH(0, prev.bottom, width, height)
          : Rect.fromXYWH(
              prev.right,
              prev.y > 0 ? prev.y : -baseline,
              width,
              height,
            );
      box = box != null ? box + cur : cur;

      consumed += t.length;
      if (consumed == length) break;
    }

    return box ?? cur;
  }
}

/// TODO: Unify this with [TextSpan.buildParagraph]
ui.Paragraph _buildParagraph(
  ChantContext ctxt,
  String text,
  Map<String, dynamic> extraProps, [
  double? resize,
]) {
  final maxWidth = _parseCssLength(extraProps['textLength']);
  final fontSizeValue = _parseCssFontSize(
    extraProps['font-size'],
    extraProps['base-font-size'],
  );
  final textStyle = ui.TextStyle(
    color: _colorFromCss(extraProps['fill'], ctxt.textColor),
    fontFamilyFallback:
        (extraProps['font-family'] ?? extraProps['base-font-family'])
            .toString()
            .split(RegExp(", ?"))
            .map((f) => f.replaceAll(RegExp(r"^'|'$"), ''))
            .toList(),
    fontSize: fontSizeValue * (resize ?? 1) / ctxt.pixelRatio,
    height: extraProps['line-height'] ?? 0.0,
    fontStyle: extraProps['font-style'] == 'italic'
        ? ui.FontStyle.italic
        : ui.FontStyle.normal,
    fontWeight: extraProps['font-weight'] == 'bold'
        ? ui.FontWeight.bold
        : ui.FontWeight.normal,
  );

  final builder = ui.ParagraphBuilder(ui.ParagraphStyle())
    ..pushStyle(textStyle)
    ..addText(text);

  final paragraph = builder.build();
  paragraph.layout(
    ui.ParagraphConstraints(
      width: maxWidth.isFinite ? maxWidth : double.infinity,
    ),
  );
  return paragraph;
}

ui.Color _colorFromCss(dynamic fill, ui.Color defaultColor) {
  if (fill is ui.Color) return fill;
  if (fill is String) {
    final value = fill.trim();
    if (value.startsWith('#')) {
      if (value.length == 7) {
        return ui.Color(int.parse('ff${value.substring(1)}', radix: 16));
      }
      if (value.length == 4) {
        final r = value[1];
        final g = value[2];
        final b = value[3];
        return ui.Color(int.parse('ff$r$r$g$g$b$b', radix: 16));
      }
    }
    if (value.toLowerCase() == 'black') return ChantColors.nigric;
    if (value.toLowerCase() == 'red') return ChantColors.rubric;
  }
  return defaultColor;
}

double _parseCssFontSize(dynamic fontSizeValue, double baseFontSize) {
  if (fontSizeValue is String && fontSizeValue.endsWith('%')) {
    final percent = double.tryParse(fontSizeValue.replaceAll('%', '')) ?? 100.0;
    return baseFontSize * percent / 100.0;
  }
  if (fontSizeValue is num) return fontSizeValue.toDouble();
  return baseFontSize;
}

double _parseCssLength(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? double.infinity;
  }
  return double.infinity;
}

const kMaxInt = -1 >>> 1;

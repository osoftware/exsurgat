import 'dart:ui' as ui;

import 'drawing.dart';
import 'elements/text/text_element.dart';

enum TextMeasuringStrategy { svg, canvas, openTypeJS }

abstract class TextMeasurer {
  const TextMeasurer();

  factory TextMeasurer.create(TextMeasuringStrategy strategy) {
    return switch (strategy) {
      TextMeasuringStrategy.canvas => CanvasTextMeasurerStrategy(),
      TextMeasuringStrategy.openTypeJS => OpenTypeTextMeasurerStrategy(),
      TextMeasuringStrategy.svg => SvgTextMeasurerStrategy(),
    };
  }

  double measureSubstring(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
  ]);

  Rect measureTextBounds(TextElement textElement, ChantContext ctxt);

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
  double measureSubstring(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
  ]) {
    if (length == 0) return 0;
    return measureTextBounds(textElement, ctxt, length).width;
  }

  @override
  Rect measureTextBounds(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
  ]) {
    late final int len;
    int consumed = 0;
    if (length == 0) {
      return Rect.fromXYWH(0, 0, 0, 0);
    } else if (length == null) {
      len = textElement.text.length;
      // } else if (length < 0) {
      //   len = textElement.text.length;
    } else {
      len = length;
    }

    Rect? box; // = Rect.fromXYWH(0, 0, 0, 0);
    Rect cur = Rect.fromXYWH(0, 0, 0, 0);
    Rect prev;

    for (final span in textElement.spans) {
      prev = cur;
      final myText = span.text.substring(0, len - consumed);
      final textAlign = textElement.textAnchor == 'middle'
          ? ui.TextAlign.center
          : ui.TextAlign.start;
      final props = <String, dynamic>{
        ...textElement.getExtraStyleProperties(ctxt),
        ...span.properties,
        'base-font-family': textElement.fontFamily(ctxt),
        'base-font-size': textElement.fontSize(ctxt),
      };
      final p = buildParagraph(
        ctxt,
        myText,
        props,
        textAlign,
        textElement.resize,
      );

      late final double width, height, baseline;
      if (p.numberOfLines > 0) {
        final metrics = p.getLineMetricsAt(0)!;
        width = metrics.width;
        height = metrics.height + metrics.descent;
        baseline = metrics.baseline;
      } else {
        width = 0;
        height = 0;
        baseline = 0;
      }

      cur = span.newLine != null
          ? Rect.fromXYWH(0, prev.bottom, width, height)
          : Rect.fromXYWH(
              prev.right,
              prev.y > 0 ? prev.y : -baseline,
              width,
              height,
            );
      if (box != null) {
        box += cur;
      } else {
        box = cur;
      }

      consumed += myText.length;
      if (consumed == len) break;
    }

    return box ?? cur;
  }

  ui.Paragraph buildParagraph(
    ChantContext ctxt,
    String text,
    Map<String, dynamic> extraProps,
    ui.TextAlign textAlign, [
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
              .split(RegExp(", ?")),
      fontSize: fontSizeValue * (resize ?? 1) / ctxt.pixelRatio,
      fontStyle: extraProps['font-style'] == 'italic'
          ? ui.FontStyle.italic
          : ui.FontStyle.normal,
      fontWeight: extraProps['font-weight'] == 'bold'
          ? ui.FontWeight.bold
          : ui.FontWeight.normal,
    );

    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: textAlign,
              textDirection: ui.TextDirection.ltr,
            ),
          )
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
      final percent =
          double.tryParse(fontSizeValue.replaceAll('%', '')) ?? 100.0;
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
}

const kMaxInt = -1 >>> 1;

final class OpenTypeTextMeasurerStrategy extends TextMeasurer {
  @override
  double measureSubstring(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
    bool returnBBox = false,
  ]) {
    final text = textElement.text;
    final safeLength = length == null || length < 0 ? text.length : length;
    final width = safeLength.toDouble() * 7.5;
    return width;
  }

  @override
  Rect measureTextBounds(TextElement textElement, ChantContext ctxt) {
    // TODO: implement measureTextBounds
    throw UnimplementedError();
  }
}

final class SvgTextMeasurerStrategy extends TextMeasurer {
  @override
  double measureSubstring(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
    bool returnBBox = false,
  ]) {
    final text = textElement.text;
    final safeLength = length == null || length < 0 ? text.length : length;
    final width = safeLength.toDouble() * 6.0;
    return width;
  }

  @override
  Rect measureTextBounds(TextElement textElement, ChantContext ctxt) {
    // TODO: implement measureTextBounds
    throw UnimplementedError();
  }
}

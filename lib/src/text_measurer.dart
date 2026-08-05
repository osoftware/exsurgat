import 'dart:ui' as ui;

import 'chant_context.dart';
import 'core.dart';
import 'elements/text/text_element.dart';

enum TextMeasuringStrategy {
  /// Measuring strategy that makes sense when positioning elements for SVG export.
  svg,

  /// Measuring strategy that makes sense when rendering on Flutter Canvas.
  canvas,
}

enum TextBoundsAlign { top, baseline }

/// Measures a rectangle that a specific text element would occupy.
abstract class TextMeasurer {
  const TextMeasurer();

  factory TextMeasurer.create(TextMeasuringStrategy strategy) {
    return switch (strategy) {
      TextMeasuringStrategy.canvas => CanvasTextMeasurerStrategy(),
      TextMeasuringStrategy.svg => SvgTextMeasurerStrategy(),
    };
  }

  /// Whether the text is rendered aligned to text baseline (like in SVG) or
  /// to top of the box (like in Flutter Canvas).
  TextBoundsAlign get align;

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

  /// Returns M-height of a given text element.
  double measureMHeight(TextElement textElement, ChantContext ctxt) {
    final paragraph = textElement.spans.first.buildParagraph(
      ctxt,
      {
        ...textElement.getExtraStyleProperties(ctxt),
        ...textElement.spans.first.properties,
        'base-font-family': textElement.fontFamily(ctxt),
        'base-font-size': textElement.fontSize(ctxt),
        'line-height': 1.0,
      },
      ui.TextAlign.start,
      textElement.resize,
    )..layout(ui.ParagraphConstraints(width: double.infinity));
    final metrics = paragraph.getLineMetricsAt(0)!;
    return metrics.ascent;
  }

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
}

/// Measuring strategy that makes sense when rendering on Flutter Canvas.
final class CanvasTextMeasurerStrategy extends TextMeasurer {
  @override
  TextBoundsAlign get align => .top;

  @override
  Rect measureTextBounds(
    TextElement textElement,
    ChantContext ctxt, [
    int? length,
  ]) {
    if (length == 0) return Rect.fromXYWH(0, 0, 0, 0);

    int consumed = 0;

    final builder = ui.ParagraphBuilder(ui.ParagraphStyle());

    for (final span in textElement.spans) {
      final t = span.text.slice(0, length == null ? null : length - consumed);
      final props = {
        ...textElement.getExtraStyleProperties(ctxt),
        ...span.properties,
        'base-font-family': textElement.fontFamily(ctxt),
        'base-font-size': textElement.fontSize(ctxt),
      };
      builder.addText('\n' * span.newLine);
      builder.addTextSpan(ctxt, t, props, textElement.resize);

      consumed += t.length;
      if (consumed == length) break;
    }

    final maxWidth = _parseCssLength(
      textElement.getExtraStyleProperties(ctxt)['textLength'],
    );
    final p = builder.build();
    p.layout(ui.ParagraphConstraints(width: maxWidth));
    if (maxWidth.isInfinite) {
      // now we can read intrinsic width
      p.layout(ui.ParagraphConstraints(width: p.maxIntrinsicWidth));
    }
    late final double width, height;
    width = p.maxIntrinsicWidth;
    height = p.height;

    return Rect.fromXYWH(0, 0, width, height);
  }
}

/// Measuring strategy that makes sense when positioning elements for SVG export.
final class SvgTextMeasurerStrategy extends TextMeasurer {
  @override
  TextBoundsAlign get align => .baseline;

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
      final t = span.text.slice(0, length == null ? null : length - consumed);
      final p = span.buildParagraph(
        ctxt,
        {
          ...textElement.getExtraStyleProperties(ctxt),
          ...span.properties,
          'base-font-family': textElement.fontFamily(ctxt),
          'base-font-size': textElement.fontSize(ctxt),
        },
        textElement.textAnchor,
        textElement.resize,
      );

      final maxWidth = _parseCssLength(
        textElement.getExtraStyleProperties(ctxt)['textLength'],
      );
      p.layout(ui.ParagraphConstraints(width: maxWidth));
      if (maxWidth.isInfinite) {
        // now we can read intrinsic width
        p.layout(ui.ParagraphConstraints(width: p.maxIntrinsicWidth));
      }
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

      cur = span.newLine > 0
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

extension on ui.ParagraphBuilder {
  void addTextSpan(
    ChantContext ctxt,
    String text,
    Map<String, dynamic> props, [
    double? resize,
  ]) {
    pushStyle(TextSpan.getTextStyle(props, ctxt, resize));
    addText(text);
    pop();
  }
}

double _parseCssLength(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? double.infinity;
  }
  return double.infinity;
}

extension on String {
  String slice(int start, [int? end]) =>
      substring(start, (end ?? 0) > length ? null : end);
}

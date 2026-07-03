import 'package:exsurgat/src/drawing.dart';

enum TextMeasuringStrategy { svg, canvas, openTypeJS }

sealed class TextMeasurer {
  const TextMeasurer();

  factory TextMeasurer.create(TextMeasuringStrategy strategy) {
    return switch (strategy) {
      TextMeasuringStrategy.canvas => CanvasTextMeasurerStrategy(),
      TextMeasuringStrategy.openTypeJS => OpenTypeTextMeasurerStrategy(),
      TextMeasuringStrategy.svg => SvgTextMeasurerStrategy(),
    };
  }

  dynamic measureSubstring(
    dynamic textElement,
    ChantContext ctxt, [
    int? length,
    bool returnBBox = false,
  ]);

  double getSubstringWidth(
    dynamic textElement,
    ChantContext ctxt, [
    int? startIndex,
    int? endIndex,
  ]) {
    if (endIndex == null) {
      endIndex = startIndex;
      startIndex = 0;
    }
    if (endIndex != null && endIndex <= (startIndex ?? 0)) return 0;

    final from = measureSubstring(textElement, ctxt, endIndex ?? 0, false);
    final to = measureSubstring(textElement, ctxt, startIndex ?? 0, false);
    return (from as num).toDouble() - (to as num).toDouble();
  }

  void recalculateMetrics(
    dynamic textElement,
    ChantContext ctxt, [
    bool resetNewLines = true,
  ]) {
    if (textElement == null) return;
    if (resetNewLines) {
      if (textElement is Map) {
        textElement.remove('maxWidth');
      }
    }
  }

  Rect measureTextBounds(dynamic textElement, ChantContext ctxt) {
    final result = measureSubstring(textElement, ctxt, null, true);
    if (result is Rect) {
      return result;
    }
    final width = (result as num).toDouble();
    return Rect.fromXYWH(0, 0, width, 16.0);
  }
}

final class CanvasTextMeasurerStrategy extends TextMeasurer {
  @override
  dynamic measureSubstring(
    dynamic textElement,
    ChantContext ctxt, [
    int? length,
    bool returnBBox = false,
  ]) {
    final text = textElement?.text?.toString() ?? '';
    final safeLength = length == null || length < 0 ? text.length : length;
    final width = safeLength.toDouble() * 8.0;
    if (returnBBox) {
      return Rect.fromXYWH(0, 0, width, 16.0);
    }
    return width;
  }
}

final class OpenTypeTextMeasurerStrategy extends TextMeasurer {
  @override
  dynamic measureSubstring(
    dynamic textElement,
    ChantContext ctxt, [
    int? length,
    bool returnBBox = false,
  ]) {
    final text = textElement?.text?.toString() ?? '';
    final safeLength = length == null || length < 0 ? text.length : length;
    final width = safeLength.toDouble() * 7.5;
    if (returnBBox) {
      return Rect.fromXYWH(0, 0, width, 16.0);
    }
    return width;
  }
}

final class SvgTextMeasurerStrategy extends TextMeasurer {
  @override
  dynamic measureSubstring(
    dynamic textElement,
    ChantContext ctxt, [
    int? length,
    bool returnBBox = false,
  ]) {
    final text = textElement?.text?.toString() ?? '';
    final safeLength = length == null || length < 0 ? text.length : length;
    final width = safeLength.toDouble() * 6.0;
    if (returnBBox) {
      return Rect.fromXYWH(0, 0, width, 14.0);
    }
    return width;
  }
}

TextMeasurer createTextMeasurer(TextMeasuringStrategy strategy) {
  return switch (strategy) {
    TextMeasuringStrategy.canvas => CanvasTextMeasurerStrategy(),
    TextMeasuringStrategy.openTypeJS => OpenTypeTextMeasurerStrategy(),
    TextMeasuringStrategy.svg => SvgTextMeasurerStrategy(),
  };
}

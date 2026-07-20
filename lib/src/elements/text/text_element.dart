import 'dart:ui';

import 'package:xml/xml.dart';

import '../../core.dart' as core;
import '../../drawing.dart';
import '../../quick_svg.dart';
import '../chant_layout_element.dart';
import 'drop_cap.dart';
import 'lyric.dart';

abstract class TextElement extends ChantLayoutElement {
  TextElement(
    ChantContext ctxt,
    String text,
    this.fontFamily,
    this.fontSize,
    this.textAnchor,
    this.sourceIndex,
    this.sourceGabc,
  ) {
    bounds = const core.Rect.fromXYWH(0, 0, 0, 0);
    origin = const core.Point(0, 0);
    selected = false;
    highlighted = false;

    dominantBaseline = 'baseline';

    generateSpansFromText(ctxt, text);
    recalculateMetrics(ctxt);
  }

  final String Function(ChantContext ctxt) fontFamily;
  final double Function(ChantContext ctxt) fontSize;
  String textAnchor;
  int sourceIndex;
  String sourceGabc;
  String dominantBaseline = 'baseline';

  late String text;
  late List<TextSpan> spans;
  late TextStyleDefinition textType;
  bool? rightAligned;
  bool needsLayout = false;
  DropCap? dropCap;
  bool? forceConnector;
  TextSpan? connectorSpan;
  double? resize;

  String getCssClasses() => textType.cssClass;
  Map<String, dynamic> getExtraStyleProperties(ChantContext ctxt) =>
      ctxt.baseTextStyle;

  void generateSpansFromText(ChantContext ctxt, String text) {
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    this.text = '';
    spans = [];

    if (text == '*' || text == '+' || text == '†') {
      final properties = text == '*'
          ? [ctxt.asteriskProperties]
          : text == '+'
          ? [ctxt.plusProperties]
          : <Map<String, dynamic>>[];
      final mapped = ctxt.specialCharText(text);
      spans.add(TextSpan(mapped, properties, []));
      return;
    }

    final markupStack = <MarkupStackFrame>[];
    var spanStartIndex = 0;
    var newLineInNextSpan = 0;

    void closeSpan(
      String spanText,
      int index, [
      Map<String, dynamic>? extraProperties,
    ]) {
      if (spanText.isEmpty && dropCap == null) return;

      this.text += spanText;
      final properties = <Map<String, dynamic>>[];
      for (final frame in markupStack) {
        properties.addAll(frame.propertyArray);
      }
      if (extraProperties != null && extraProperties.isNotEmpty) {
        properties.add(extraProperties);
      }

      final span = TextSpan(
        spanText,
        properties,
        markupStack.map((frame) => frame.tagName).toList(),
        index,
      );
      if (newLineInNextSpan != 0) {
        span.newLine = newLineInNextSpan;
        newLineInNextSpan = 0;
      }
      spans.add(span);
    }

    // Text markup parser stubbed for Dart port.
    closeSpan(text.substring(spanStartIndex), spanStartIndex);
  }

  String getCanvasFontForProperties(
    ChantContext ctxt, [
    Map<String, dynamic> properties = const {},
  ]) {
    final buffer = StringBuffer();
    if (properties['font-style'] == 'italic') buffer.write('italic ');
    if (properties['font-variant'] == 'small-caps') buffer.write('small-caps ');
    if (properties['font-weight'] == 'bold') buffer.write('bold ');

    var computedFontSize = fontSize(ctxt);
    final fontSizeValue = properties['font-size'];
    if (fontSizeValue is String && fontSizeValue.endsWith('%')) {
      final percent = double.tryParse(fontSizeValue.replaceAll('%', '')) ?? 100;
      computedFontSize = computedFontSize * percent / 100;
    } else if (fontSizeValue is num) {
      computedFontSize = fontSizeValue.toDouble();
    }

    buffer.write('${computedFontSize * (resize ?? 1)}px ');
    buffer.write(properties['font-family'] ?? fontFamily(ctxt));
    return buffer.toString();
  }

  double measureSubstring(ChantContext ctxt, [int? length]) =>
      ctxt.textMeasurer.measureSubstring(this, ctxt, length);

  void recalculateMetrics(ChantContext ctxt, [bool resetNewLines = true]) =>
      ctxt.textMeasurer.recalculateMetrics(this, ctxt, resetNewLines);

  // TODO: hallucination
  void setMaxWidth(
    ChantContext ctxt,
    double maxWidth, [
    double firstLineMaxWidth = double.nan,
  ]) {
    if (spans.any((s) => s.newLine != null)) {
      recalculateMetrics(ctxt);
    }
    if (bounds.width > maxWidth) {
      final percentage = maxWidth / bounds.width;
      if (this is Lyric && percentage >= 0.85) {
        resize = percentage;
      }
      recalculateMetrics(ctxt, false);
    }
  }

  Map<String, dynamic> getSvgProps() {
    return {
      'source-index': sourceIndex,
      'x': bounds.x,
      'y': bounds.y,
      'class': getCssClasses().trim(),
      'text-anchor': textAnchor,
    };
  }

  Map<String, dynamic> getSpanOptions(
    TextSpan span,
    ChantContext ctxt, [
    bool useStyleObject = false,
  ]) {
    final options = <String, dynamic>{
      'source-index': span.index,
      'class': span.properties['class'],
      'style': useStyleObject
          ? span.properties
          : getCssForProperties(span.properties),
    };
    if (span.newLine != null) {
      final xOffset = span.xOffset ?? 0.0;
      options['dy'] = '${1.1 * (int.tryParse(span.newLine.toString()) ?? 1)}em';
      options['x'] = bounds.x + xOffset;
    } else if (span.xOffset != null) {
      options['x'] = bounds.x + span.xOffset!;
    }
    if (span.properties.containsKey('textLength')) {
      options['textLength'] = span.properties['textLength'];
      options['lengthAdjust'] = 'spacingAndGlyphs';
      options['y'] = bounds.y;
    }
    if (resize != null) {
      options['font-size'] =
          span.properties['font-size'] ?? fontSize(ctxt) * resize!;
    }
    return options;
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    final spansXml = spans
        .map(
          (span) => QuickSvg.createNode(
            'tspan',
            getSpanOptions(span, ctxt),
            span.text,
          ),
        )
        .toList();
    final options = getSvgProps();
    final extraStyleProperties = getExtraStyleProperties(ctxt);
    options['style'] = getCssForProperties(extraStyleProperties);
    if (extraStyleProperties['class'] != null) {
      options['class'] = '${extraStyleProperties['class']} ${options['class']}';
    }
    return QuickSvg.createNode('text', options, spansXml);
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    final spansTree = spans
        .map(
          (span) => QuickSvg.createSvgTree(
            'tspan',
            getSpanOptions(span, ctxt, true),
            span.text,
          ),
        )
        .toList();
    final options = getSvgProps();
    final extraStyleProperties = getExtraStyleProperties(ctxt);
    options['style'] = extraStyleProperties;
    if (extraStyleProperties['class'] != null) {
      options['class'] = '${extraStyleProperties['class']} ${options['class']}';
    }
    return QuickSvg.createSvgTree('text', options, spansTree);
  }

  @override
  String createSvgFragment(ChantContext ctxt, [ChantLayoutElement? source]) {
    final spansFragment = spans
        .map(
          (span) => QuickSvg.createFragment(
            'tspan',
            getSpanOptions(span, ctxt),
            escapeForTspan(span.text),
          ),
        )
        .join();
    final options = getSvgProps();
    final extraStyleProperties = getExtraStyleProperties(ctxt);
    options['style'] = getCssForProperties(extraStyleProperties);
    if (extraStyleProperties['class'] != null) {
      options['class'] = '${extraStyleProperties['class']} ${options['class']}';
    }
    if (ctxt.setFontFamilyAttributes) {
      options['font-size'] = fontSize(ctxt);
    }
    return QuickSvg.createFragment('text', options, spansFragment);
  }

  @override
  void draw(ChantContext ctxt) {
    final canvas = ctxt.canvasCtxt;
    final textAlign = textAnchor == 'middle'
        ? TextAlign.center
        : TextAlign.start;
    var translateWidth = 0.0;

    canvas.save();
    for (final span in spans) {
      final xOffset = span.xOffset ?? 0.0;
      if (span.newLine != null) {
        final count = int.tryParse(span.newLine.toString()) ?? 1;
        canvas.translate(translateWidth + xOffset, fontSize(ctxt) * count);
        translateWidth = -xOffset;
      } else if (xOffset != 0.0) {
        canvas.translate(translateWidth + xOffset, 0);
        translateWidth = -xOffset;
      }

      final properties = <String, dynamic>{
        ...getExtraStyleProperties(ctxt),
        'base-font-family': fontFamily(ctxt),
        'base-font-size': fontSize(ctxt),
      };

      final paragraph = span.buildParagraph(
        ctxt,
        properties,
        textAlign,
        resize,
      );

      canvas.drawParagraph(paragraph, Offset(bounds.x, bounds.y));

      final metricsWidth = paragraph.width;
      translateWidth -= metricsWidth;
      canvas.translate(metricsWidth, 0);
    }
    canvas.restore();
  }
}

class TextSpan {
  TextSpan(
    this.text,
    this.propertyArray,
    this.activeTags, [
    this.index = 0,
    Map<String, dynamic>? extraProps,
  ]) {
    if (extraProps != null) {
      xOffset = extraProps['xOffset'] as double?;
      newLine = extraProps['newLine'];
    }
  }

  String text;
  final List<Map<String, dynamic>> propertyArray;
  final List<String> activeTags;
  final int index;
  double? xOffset;
  int? newLine;

  Map<String, dynamic> get properties {
    final result = <String, dynamic>{};
    for (final props in propertyArray) {
      result.addAll(props);
    }
    if (xOffset != null) result['xOffset'] = xOffset;
    if (newLine != null) result['newLine'] = newLine;
    return result;
  }

  TextSpan clone() {
    final result = TextSpan(
      text,
      List<Map<String, dynamic>>.from(propertyArray),
      List<String>.from(activeTags),
      index,
    );
    result.xOffset = xOffset;
    result.newLine = newLine;
    return result;
  }

  Paragraph buildParagraph(
    ChantContext ctxt,
    Map<String, dynamic> extraProps,
    TextAlign textAlign, [
    double? resize,
  ]) {
    final maxWidth = _parseCssLength(properties['textLength']);
    final fontSizeValue = _parseCssFontSize(
      extraProps['font-size'],
      extraProps['base-font-size'],
    );
    final textStyle = TextStyle(
      color: _colorFromCss(extraProps['fill'], ctxt.textColor),
      fontFamilyFallback:
          (extraProps['font-family'] ?? extraProps['base-font-family'])
              .toString()
              .split(RegExp(", ?")),
      fontSize: fontSizeValue * (resize ?? 1),
      fontStyle: extraProps['font-style'] == 'italic'
          ? FontStyle.italic
          : FontStyle.normal,
      fontWeight: extraProps['font-weight'] == 'bold'
          ? FontWeight.bold
          : FontWeight.normal,
    );

    final builder =
        ParagraphBuilder(
            ParagraphStyle(
              textAlign: textAlign,
              textDirection: TextDirection.ltr,
            ),
          )
          ..pushStyle(textStyle)
          ..addText(text);

    final paragraph = builder.build();
    paragraph.layout(
      ParagraphConstraints(
        width: maxWidth.isFinite ? maxWidth : double.infinity,
      ),
    );
    return paragraph;
  }

  Color _colorFromCss(dynamic fill, Color defaultColor) {
    if (fill is Color) return fill;
    if (fill is String) {
      final value = fill.trim();
      if (value.startsWith('#')) {
        if (value.length == 7) {
          return Color(int.parse('ff${value.substring(1)}', radix: 16));
        }
        if (value.length == 4) {
          final r = value[1];
          final g = value[2];
          final b = value[3];
          return Color(int.parse('ff$r$r$g$g$b$b', radix: 16));
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

class MarkupStackFrame {
  MarkupStackFrame(
    this.tagName,
    this.startIndex,
    this.propertyArray, [
    this.symbol = '',
  ]);

  final String tagName;
  final int startIndex;
  final List<Map<String, dynamic>> propertyArray;
  final String symbol;

  Map<String, dynamic> get properties {
    final result = <String, dynamic>{};
    for (final props in propertyArray) {
      result.addAll(props);
    }
    return result;
  }

  static MarkupStackFrame createStackFrame(
    ChantContext ctxt,
    String tagName,
    int startIndex, [
    Map<String, dynamic> extraProperties = const {},
    String symbol = '',
  ]) {
    return MarkupStackFrame(tagName, startIndex, [
      ctxt.fontStyleDictionary[tagName] ?? {},
      extraProperties,
    ], symbol);
  }
}

const Map<String, String> _subsForTspans = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
};

String escapeForTspan(String string) {
  return string.replaceAllMapped(
    RegExp(r'[&<>]'),
    (match) => _subsForTspans[match[0]] ?? match[0]!,
  );
}

String getCssForProperties(Map<String, dynamic> properties) {
  return properties.entries
      .where((entry) => entry.key != 'class' && entry.value != null)
      .map((entry) => '${entry.key}: ${entry.value};')
      .join();
}

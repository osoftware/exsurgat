import 'dart:math' as math;
import 'dart:ui';

import 'package:xml/xml.dart';

import 'core.dart';
import 'glyphs.dart';
import 'quick_svg.dart';
import 'text.dart';
import 'text_measurer.dart';

export 'core.dart';

String resolveFontFilenameForProperties(
  Map<String, dynamic> properties, [
  String? fontFamily,
]) {
  return fontFamily ?? 'Regular';
}

enum LyricType {
  singleSyllable,
  beginningSyllable,
  middleSyllable,
  endingSyllable,
  directive,
}

class TextStyleDefinition {
  const TextStyleDefinition({this.defaultSize, this.size, this.cssClass = ''});

  final double Function(double size, ChantContext ctxt)? defaultSize;
  final double Function(ChantContext ctxt)? size;
  final String cssClass;
}

final Map<String, TextStyleDefinition> TextTypes = {
  'al': TextStyleDefinition(cssClass: 'al'),
  'translation': TextStyleDefinition(cssClass: 'translation'),
  'dropCap': TextStyleDefinition(cssClass: 'dropCap'),
  'annotation': TextStyleDefinition(cssClass: 'annotation'),
  'lyric': TextStyleDefinition(
    cssClass: 'lyric',
    defaultSize: (size, ctxt) => size * 0.9,
  ),
};

class ChantColors {
  static const Color nigric = Color(0xFF000000);
  static const Color rubric = Color(0xFFDD0000);
}

class ChantContext {
  ChantContext({
    TextMeasuringStrategy textMeasuringStrategy = TextMeasuringStrategy.canvas,
  }) {
    textMeasurer = TextMeasurer.create(textMeasuringStrategy);
    getFontFilenameForProperties = resolveFontFilenameForProperties;
    specialCharText = (String char) => specialCharMap[char] ?? char;
    defsNode = QuickSvg.createNode('defs');

    setFont("'Palatino Linotype', 'Book Antiqua', Palatino, serif", 16);

    specialCharProperties.addAll({
      'font-family': "'Exsurge Characters'",
      'fill': rubricColor,
      'class': 'rubric',
    });
    specialCharText = (String char) => specialCharMap[char] ?? char;

    fontStyleDictionary.addAll({
      'b': {'font-weight': 'bold'},
      'i': {'font-style': 'italic'},
      'u': {'text-decoration': 'underline'},
      'ul': {'text-decoration': 'underline'},
      'c': {'fill': rubricColor, 'class': 'rubric'},
      'sc': {'font-variant': 'small-caps'},
      'v': {},
      'e': {'font-style': 'italic', 'font-size': '90%'},
    });

    textStyles['al'] ??= {};
    textStyles['al']['prefix'] = '<i>';
    textStyles['translation'] ??= {};
    textStyles['translation']['prefix'] = '<i>';

    textStyles['dropCap'] ??= {};
    textStyles['dropCap']['padding'] = 1;
    textStyles['annotation'] ??= {};
    textStyles['annotation']['padding'] = 1;

    glyphPunctumWidth = glyphs[GlyphCode.punctumQuadratum]!.bounds.width;
    glyphPunctumHeight = glyphs[GlyphCode.punctumQuadratum]!.bounds.height;

    activeClef = null;

    setGlyphScaling(1.0 / 16.0);

    activeNotations = null;

    setMergeAnnotationWithTextLeft(true);
  }

  final Map<String, dynamic> fontDictionary = {};
  int staffLineCount = 4;
  late TextMeasurer textMeasurer;
  late String Function(Map<String, dynamic> properties, [String? fontFamily])
  getFontFilenameForProperties;
  final Map<String, dynamic> defs = {};
  final List<void Function()> makeDefs = [];
  late final XmlElement defsNode;

  final Map<String, dynamic> textStyles = {};
  Color textColor = ChantColors.nigric;
  Color rubricColor = ChantColors.rubric;
  final Map<String, dynamic> specialCharProperties = {};
  String textBeforeSpecialChar = '';
  String textAfterSpecialChar = '.';
  final Map<String, String> specialCharMap = {
    '℣': 'v',
    '℟': 'r',
    '+': '+',
    '*': '*',
  };
  final Map<String, dynamic> plusProperties = {};
  final Map<String, dynamic> asteriskProperties = {};
  late String Function(String char) specialCharText;
  final Map<String, Map<String, dynamic>> fontStyleDictionary = {};
  final Map<String, String> markupSymbolDictionary = {
    '*': 'b',
    '_': 'i',
    '^': 'c',
    '%': 'sc',
  };

  double minLedgerSeparation = 2;
  double minSpaceAboveStaff = 2;
  double minSpaceBelowStaff = 1;
  double spaceBetweenSystems = 1.5;
  double glyphPunctumWidth = 0;
  double glyphPunctumHeight = 0;
  double maxExtraSpaceInStaffIntervals = 0.5;
  dynamic activeClef;
  Color neumeLineColor = ChantColors.nigric;
  Color staffLineColor = ChantColors.nigric;
  Color dividerLineColor = ChantColors.nigric;
  Language defaultLanguage = Latin();
  String syllableConnector = '-';
  bool scaleDefs = true;
  double glyphScaling = 1.0;
  double staffInterval = 0;
  double staffLineWeight = 0;
  double neumeLineWeight = 0;
  double dividerLineWeight = 0;
  double episemaLineWeight = 0;
  double intraNeumeSpacing = 0;
  double interSyllabicMultiplier = 2.5;
  double accidentalSpaceMultiplier = 2;
  double interVerbalMultiplier = 1;
  bool drawGuides = false;
  bool drawDebuggingBounds = false;
  bool setFontFamilyAttributes = false;
  List<dynamic> notations = [];
  dynamic activeNotations;
  int currNotationIndex = -1;
  int minSyllablesLastLine = 0;
  int minNotesLastLine = 0;
  double condensingTolerance = 0.3;
  bool autoColor = true;
  bool useExtraTextOnly = true;
  String noteIdPrefix = 'note-';
  double hyphenWidth = 0;
  double minLyricWordSpacing = 1.0;
  List<dynamic> Function(List<dynamic> annotationSpans)?
  mergeAnnotationWithTextLeft;
  dynamic baseTextStyle;

  late Canvas canvasCtxt;

  @Deprecated('should be irrelevant')
  double pixelRatio = 1.0;

  int convertStaffPositionToSymmetric(int staffPosition) =>
      staffPosition - staffLineCount;

  int convertSymmetricStaffPosition(int staffPositionSymmetric) =>
      staffPositionSymmetric + staffLineCount;

  dynamic getFontForProperties([
    Map<String, dynamic> properties = const <String, dynamic>{},
    String? fontFamily,
  ]) {
    final keyWithFontFamily = getFontFilenameForProperties(
      properties,
      fontFamily,
    );
    return fontDictionary[keyWithFontFamily] ??
        fontDictionary[fontFamily ?? ''] ??
        fontDictionary['Regular'];
  }

  void setFont(
    String font, [
    double size = 16,
    dynamic baseStyle = const {},
    Map<String, dynamic>? fontDictionary,
  ]) {
    for (final entry in TextTypes.entries) {
      final textStyle = textStyles[entry.key] ?? <String, dynamic>{};
      textStyles[entry.key] = textStyle;
      textStyle['size'] =
          entry.value.defaultSize?.call(size, this) ??
          entry.value.size?.call(this) ??
          size;
      textStyle['font'] = font;
      textStyle['color'] = textColor;
    }

    baseTextStyle = baseStyle;

    if (fontDictionary != null) {
      this.fontDictionary.addAll(fontDictionary);
      textMeasuringStrategy = TextMeasuringStrategy.openTypeJS;
    }
  }

  set textMeasuringStrategy(TextMeasuringStrategy strategy) {
    textMeasurer = createTextMeasurer(strategy);
  }

  void setRubricColor(Color color) {
    rubricColor = color;
    specialCharProperties['fill'] = color;
    fontStyleDictionary['c']?['fill'] = color;
  }

  void setMergeAnnotationWithTextLeft(bool merge) {
    mergeAnnotationWithTextLeft = merge ? __mergeAnnotationWithTextLeft : null;
  }

  void setScaleDefs(bool scaleDefs) {
    final scaled = scaleDefs;
    if (this.scaleDefs != scaled) {
      this.scaleDefs = scaled;
      setGlyphScaling(glyphScaling);
    }
  }

  String createStyleCss() {
    final buffer = StringBuffer();
    for (final entry in TextTypes.entries) {
      final style = textStyles[entry.key] ?? {};
      final cssClass = entry.value.cssClass;
      final color = style['color'] ?? textColor;
      final font = style['font'] ?? 'serif';
      final size = style['size'] ?? 16;
      buffer.writeln(
        'svg.Exsurge .$cssClass{fill:$color;font-family:$font;font-size:${size}px;font-kerning:normal}',
      );
    }
    return buffer.toString();
  }

  XmlElement createStyleNode() {
    return QuickSvg.createNode('style', {}, createStyleCss());
  }

  SvgTreeNode createStyleTree() {
    return QuickSvg.createSvgTree(
      'style',
      <String, dynamic>{},
      createStyleCss(),
    );
  }

  String createStyle() => '<style>${createStyleCss()}</style>';

  void updateHyphenWidth() {
    final hyphen = Lyric(this, syllableConnector, LyricType.singleSyllable);
    final multiplier =
        minLyricWordSpacing /
        (hyphenWidth == 0 ? minLyricWordSpacing : hyphenWidth);
    hyphenWidth = hyphen.bounds.width == 0 ? 1.0 : hyphen.bounds.width;
    minLyricWordSpacing = multiplier * hyphenWidth;
  }

  void setStaffHeight(double staffHeight) {
    setGlyphScaling(staffHeight / 600);
  }

  void setGlyphScaling(double glyphScaling) {
    this.glyphScaling = glyphScaling;
    staffInterval = glyphPunctumWidth * glyphScaling;
    staffLineWeight = (5 * staffInterval / 8).ceil() / 5;
    neumeLineWeight = staffLineWeight;
    dividerLineWeight = neumeLineWeight;
    episemaLineWeight = neumeLineWeight * 1.25;
    intraNeumeSpacing = staffInterval / 2.0;

    defsNode.children.clear();
    for (final makeDef in makeDefs) {
      makeDef();
    }

    updateHyphenWidth();
  }

  double calculateHeightFromStaffPosition(int staffPosition) =>
      -staffPosition * staffInterval;

  dynamic findNextNeume() {
    if (currNotationIndex < 0) {
      throw StateError(
        'findNextNeume() called without a valid currNotationIndex set',
      );
    }

    for (int i = currNotationIndex + 1; i < (notations.length); i++) {
      final notation = notations[i];
      if (notation.isNeume == true && !notation.hasNoWidth) {
        return notation;
      }
    }

    return null;
  }

  void makeCanvas(PictureRecorder pictureRecorder) {
    canvasCtxt = Canvas(pictureRecorder);
  }

  void attachCanvas(Canvas canvas) {
    canvasCtxt = canvas;
  }

  void setCanvasSize(double width, double height, [double scale = 1]) {}
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
  Object? newLine;

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

class TextElement extends ChantLayoutElement {
  TextElement(
    ChantContext ctxt,
    String text,
    this.fontFamily,
    this.fontSize,
    this.textAnchor,
    this.sourceIndex,
    this.sourceGabc,
  ) {
    bounds = const Rect.fromXYWH(0, 0, 0, 0);
    origin = const Point(0, 0);
    selected = false;
    highlighted = false;

    dominantBaseline = 'baseline';

    generateSpansFromText(ctxt, text);
    recalculateMetrics(ctxt);
  }

  final String Function(ChantContext ctxt) fontFamily;
  final double Function(ChantContext ctxt) fontSize;
  final String textAnchor;
  int sourceIndex;
  String sourceGabc;
  String dominantBaseline = 'baseline';

  late String text;
  late List<TextSpan> spans;
  List<String>? textType;
  bool? rightAligned;
  bool? needsLayout;
  DropCap? dropCap;
  bool? forceConnector;
  TextSpan? connectorSpan;
  double? resize;

  String getCssClasses() => '';
  Map<String, dynamic> getExtraStyleProperties(ChantContext ctxt) =>
      ctxt.baseTextStyle ?? {};

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

  dynamic measureSubstring(
    ChantContext ctxt, [
    int? length,
    bool returnBBox = false,
  ]) {
    return ctxt.textMeasurer.measureSubstring(this, ctxt, length, returnBBox);
  }

  void recalculateMetrics(ChantContext ctxt, [bool resetNewLines = true]) {
    ctxt.textMeasurer.recalculateMetrics(this, ctxt, resetNewLines);
  }

  void setMaxWidth(
    ChantContext ctxt,
    double maxWidth, [
    double firstLineMaxWidth = double.nan,
  ]) {
    if (spans.where((s) => s.newLine == true).isNotEmpty) {
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
  XmlElement createSvgNode(ChantContext ctxt) {
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
    options['source'] = this;
    return QuickSvg.createNode('text', options, spansXml);
  }

  SvgTreeNode createSvgTree(ChantContext ctxt) {
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
    options['source'] = this;
    return QuickSvg.createSvgTree('text', options, spansTree);
  }

  @override
  String createSvgFragment(ChantContext ctxt) {
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

      final properties = <String, dynamic>{};
      properties.addAll(getExtraStyleProperties(ctxt));
      properties.addAll(span.properties);

      final paragraph = _buildParagraph(
        ctxt,
        span.text,
        properties,
        textAlign,
        _parseCssLength(span.properties['textLength']),
      );

      canvas.drawParagraph(paragraph, Offset(bounds.x, bounds.y));

      final metricsWidth = paragraph.width;
      translateWidth -= metricsWidth;
      canvas.translate(metricsWidth, 0);
    }
    canvas.restore();
  }

  Paragraph _buildParagraph(
    ChantContext ctxt,
    String text,
    Map<String, dynamic> properties,
    TextAlign textAlign,
    double maxWidth,
  ) {
    final fontSizeValue = _parseCssFontSize(
      properties['font-size'],
      fontSize(ctxt),
    );
    final textStyle = TextStyle(
      color: _colorFromCss(properties['fill'], ctxt.textColor),
      fontFamily: properties['font-family'] ?? fontFamily(ctxt),
      fontSize: fontSizeValue * (resize ?? 1),
      fontStyle: properties['font-style'] == 'italic'
          ? FontStyle.italic
          : FontStyle.normal,
      fontWeight: properties['font-weight'] == 'bold'
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
    List<dynamic> lyricArray,
    bool presumeConnectorNeeded,
  ) {
    if (lyricArray.isEmpty) return double.nan;
    var x = -double.maxFinite;
    for (final lyric in lyricArray) {
      if (lyric != null) {
        x = math.max(
          x,
          lyric.notation.bounds.x +
              lyric.bounds.x +
              lyric.bounds.width +
              (presumeConnectorNeeded &&
                      lyric.allowsConnector() &&
                      !lyric.needsConnector
                  ? lyric.getConnectorWidth()
                  : 0),
        );
      }
    }
    return x;
  }

  static bool hasOnlyOneLyric(List<dynamic> lyricArray) {
    return lyricArray.where((l) => l.originalText != null).length == 1;
  }

  static int indexOfLyric(List<dynamic> lyricArray) {
    final filtered = lyricArray.where((l) => l.originalText != null).toList();
    return lyricArray.indexOf(filtered.isNotEmpty ? filtered[0] : null);
  }

  static void mergeIn(List<dynamic> lyricArray, List<dynamic> newLyrics) {
    for (var i = 0; i < newLyrics.length; ++i) {
      if (newLyrics[i].originalText != null || lyricArray[i] == null) {
        lyricArray[i] = newLyrics[i];
      }
    }
  }

  static void mergeInArray(List<dynamic> lyricArray, List<dynamic> notations) {
    for (var i = 0; i < notations.length; ++i) {
      mergeIn(lyricArray, notations[i].lyrics as List<dynamic>);
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
    textType = ['lyric'];
    originalText = text;
    centerStartIndex = -1;
    centerLength = text.length;
    needsConnector = false;
    language = null;
    if (allowsConnector()) {
      connectorSpan = TextSpan(ctxt.syllableConnector, [], []);
    }
  }

  final dynamic notation;
  final dynamic notations;
  late LyricType lyricType;
  late String originalText;
  int centerStartIndex = -1;
  int centerLength = 0;
  bool needsConnector = false;
  late double widthWithoutConnector;
  late double vowelSegmentWidth;
  double? connectorWidth;
  double? defaultConnectorWidth;
  dynamic language;

  bool allowsConnector() =>
      lyricType == LyricType.beginningSyllable ||
      lyricType == LyricType.middleSyllable;

  void setForceConnector(bool force) {
    forceConnector = force && allowsConnector();
  }

  void setNeedsConnector([bool needs = false, double? width]) {
    if (needs || (forceConnector ?? false)) {
      needsConnector = true;
      if (width != null) {
        setConnectorWidth(width);
      } else {
        bounds = Rect.fromXYWH(
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
      bounds = Rect.fromXYWH(
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
      bounds = Rect.fromXYWH(
        bounds.x,
        bounds.y,
        widthWithoutConnector + getConnectorWidth(),
        bounds.height,
      );
    }
  }

  double getConnectorWidth() => connectorWidth ?? defaultConnectorWidth ?? 0;

  double getLeft() => notation.bounds.x + bounds.x;

  double getRight() => notation.bounds.x + bounds.x + bounds.width;

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

    bounds = Rect.fromXYWH(-offset, bounds.y, bounds.width, bounds.height);
    origin = Point(offset, origin.y);
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

    return dropCap;
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

class DropCap extends TextElement {
  DropCap(ChantContext ctxt, String text, int sourceIndex)
    : super(
        ctxt,
        (ctxt.textStyles['dropCap']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['dropCap']?['font'],
        (ctxt) => ctxt.textStyles['dropCap']?['size'],
        'middle',
        sourceIndex,
        text,
      ) {
    textType = ['dropCap'];
    padding =
        ctxt.staffInterval * (ctxt.textStyles['dropCap']?['padding'] ?? 1);
  }

  late double padding;
}

final TextSpan __connectorSpan = TextSpan(' • ', [], []);

List<dynamic> __mergeAnnotationWithTextLeft(List<dynamic> annotationSpans) {
  var result = <dynamic>[];
  for (final spans in annotationSpans) {
    if (result.isNotEmpty) {
      if (spans.isNotEmpty) {
        result.add(__connectorSpan);
        result.addAll(spans);
      }
    } else if (spans.isNotEmpty) {
      result.addAll(spans);
    }
  }
  return result;
}

abstract class ChantLayoutElement {
  ChantLayoutElement() {
    bounds = const Rect.fromXYWH(0, 0, 0, 0);
    origin = const Point(0, 0);

    selected = false;
    highlighted = false;
  }

  late Rect bounds;
  late Point origin;
  late bool selected;
  late bool highlighted;

  void draw(ChantContext ctxt);

  XmlElement createSvgNode(ChantContext ctxt);

  String createSvgFragment(ChantContext ctxt);
}

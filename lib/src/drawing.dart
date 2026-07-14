import 'dart:ui';

import 'package:exsurgat/src/elements/notation/chant_notation_element.dart';
import 'package:xml/xml.dart';

import 'elements/brace_point.dart';
import 'elements/notation/clefs/clef.dart';
import 'elements/notation/neumes/neume.dart';
import 'elements/text/lyric.dart';
import 'elements/text/text_element.dart';
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
  'choralSign': TextStyleDefinition(cssClass: 'choralSign'),
  'supertitle': TextStyleDefinition(cssClass: 'supertitle'),
  'title': TextStyleDefinition(cssClass: 'title'),
  'subtitle': TextStyleDefinition(cssClass: 'subtitle'),
  'leftRight': TextStyleDefinition(cssClass: 'leftRight'),
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
  final List<SvgTreeNode Function()> makeDefs = [];
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
  Clef? activeClef;
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
  List<ChantNotationElement> notations = [];
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
  List<dynamic> Function(List<List<TextSpan>> annotationSpans)?
  mergeAnnotationWithTextLeft;
  Map<String, dynamic> baseTextStyle = {};
  bool editable = false;
  bool startExtraTextOnlyFromFirst = false;

  late Canvas canvasCtxt;

  @Deprecated('should be irrelevant')
  double pixelRatio = 1.0;

  BracePoint? lastStartBrace;

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
    Map<String, dynamic> baseStyle = const {},
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
    textMeasurer = TextMeasurer.create(strategy);
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
      final color = (style['color'] as Color? ?? textColor).toSvgString();
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

  double calculateHeightFromStaffPosition(num staffPosition) =>
      -staffPosition * staffInterval;

  Neume? findNextNeume() {
    if (currNotationIndex < 0) {
      throw StateError(
        'findNextNeume() called without a valid currNotationIndex set',
      );
    }

    for (int i = currNotationIndex + 1; i < (notations.length); i++) {
      final notation = notations[i];
      if (notation is Neume && !notation.hasNoWidth) {
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

enum MarkingPositionHint { defaultHint, above, below }

final TextSpan __connectorSpan = TextSpan(' • ', [], []);

List<dynamic> __mergeAnnotationWithTextLeft(
  List<List<TextSpan>> annotationSpans,
) {
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

extension CanvasPathBuilderExtension on Canvas {
  CanvasPathBuilder beginPath({
    required double strokeWidth,
    required Color color,
  }) => CanvasPathBuilder(this, strokeWidth: strokeWidth, color: color);
}

/// Mimic HTML5 canvas
class CanvasPathBuilder {
  final Path _path = Path();
  final Canvas _canvas;
  bool _disposed = false;

  double strokeWidth;
  Color color;

  CanvasPathBuilder(
    this._canvas, {
    required this.strokeWidth,
    required this.color,
  });

  void moveTo(double x, double y) {
    _path.moveTo(x, y);
  }

  void lineTo(double x, double y) {
    _path.lineTo(x, y);
  }

  void stroke() {
    if (_disposed) {
      throw StateError('This path has already been drawn.');
    }
    _canvas.drawPath(
      _path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = strokeWidth,
    );
    _disposed = true;
  }
}

extension Svg on Color {
  String toSvgString() {
    return "rgb(${r * 100}% ${g * 100}% ${b * 100}% / $a)";
  }
}

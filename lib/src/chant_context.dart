import 'dart:ui';

import 'package:xml/xml.dart';

import 'chant_theme.dart';
import 'drawing.dart';
import 'elements/brace_point.dart';
import 'elements/notation/chant_notation_element.dart';
import 'elements/notation/clefs/clef.dart';
import 'elements/notation/neumes/neume.dart';
import 'elements/text/lyric.dart';
import 'elements/text/text_element.dart';
import 'glyphs.dart';
import 'language.dart';
import 'quick_svg.dart';
import 'text_measurer.dart';

class ChantContext {
  ChantContext({
    TextMeasuringStrategy textMeasuringStrategy = TextMeasuringStrategy.canvas,
    this.stylingMode = StylingMode.attributes,
    ChantTheme? theme,
  }) : textMeasurer = TextMeasurer.create(textMeasuringStrategy),
       defsNode = QuickSvg.createNode('defs') {
    specialCharProperties.addAll({'class': 'rubric'});
    specialCharText = (c) => c;

    fontStyleDictionary.addAll({
      'b': {'font-weight': 'bold'},
      'i': {'font-style': 'italic'},
      'u': {'text-decoration': 'underline'},
      'ul': {'text-decoration': 'underline'},
      'c': {'class': 'rubric'},
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
    setMergeAnnotationWithTextLeft(true);

    this.theme = theme ?? ChantTheme();
  }

  late ChantTheme _theme;
  ChantTheme get theme => _theme;
  set theme(ChantTheme value) {
    _theme = value;
    _setFont(_theme);
    _setRubricColor(_theme.rubricColor);
  }

  StylingMode stylingMode;
  final Map<String, dynamic> fontDictionary = {};
  int staffLineCount = 4;
  late TextMeasurer textMeasurer;
  final Map<String, dynamic> defs = {};
  final List<SvgTreeNode Function()> makeDefs = [];
  late final XmlElement defsNode;

  final Map<String, dynamic> textStyles = {};
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

  late double glyphPunctumWidth;
  late double glyphPunctumHeight;
  double maxExtraSpaceInStaffIntervals = 0.5;
  Clef? activeClef;

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

  late Canvas canvas;

  BracePoint? lastStartBrace;

  int convertStaffPositionToSymmetric(int staffPosition) =>
      staffPosition - staffLineCount;

  int convertSymmetricStaffPosition(int staffPositionSymmetric) =>
      staffPositionSymmetric + staffLineCount;

  void _setFont(ChantTheme theme) {
    for (final entry in theme.textStyles.entries) {
      final textStyle = textStyles[entry.key] ?? <String, dynamic>{};
      textStyles[entry.key] = textStyle;
      textStyle['size'] =
          entry.value.relativeSize?.call(theme.baseTextStyle.size) ??
          entry.value.size?.call(this) ??
          theme.baseTextStyle.size;
      textStyle['font'] = entry.value.font ?? theme.baseTextStyle.font;
      textStyle['fill'] = entry.value.color;
    }

    baseTextStyle = theme.baseTextStyle.baseStyle;
  }

  set textMeasuringStrategy(TextMeasuringStrategy strategy) {
    textMeasurer = TextMeasurer.create(strategy);
  }

  void _setRubricColor(Color color) {
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
    for (final entry in theme.textStyles.entries) {
      final style = textStyles[entry.key] ?? {};
      final cssClass = entry.key;
      final color = (style['color'] as Color? ?? theme.textColor).toSvgString();
      final font = style['font'] ?? 'serif';
      final size = style['size'] ?? 16;
      buffer.writeln(
        '.$cssClass { fill:$color; font-family:$font; font-size:${size}px; font-kerning:normal; }',
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
    canvas = Canvas(pictureRecorder);
  }

  void attachCanvas(Canvas canvas) {
    this.canvas = canvas;
  }
}

final TextSpan __connectorSpan = TextSpan(' • ', [], []);

List<TextSpan> __mergeAnnotationWithTextLeft(
  List<List<TextSpan>> annotationSpans,
) {
  var result = <TextSpan>[];
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

enum MarkingPositionHint { defaultHint, above, below }

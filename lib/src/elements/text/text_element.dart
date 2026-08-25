import 'dart:ui';

import 'package:xml/xml.dart';

import '../../chant_context.dart';
import '../../chant_theme.dart';
import '../../core.dart' as core;
import '../../drawing.dart';
import '../../glyphs.dart' as glyphs;
import '../../language.dart' show addAccent, makeLigature;
import '../../quick_svg.dart';
import '../chant_layout_element.dart';
import 'drop_cap.dart';
import 'lyric.dart';

abstract class TextElement extends ChantLayoutElement {
  TextElement({
    required ChantContext ctxt,
    required String text,
    required this.cssClass,
    required this.fontFamily,
    required this.fontSize,
    required this.textAnchor,
    required this.sourceIndex,
    required this.sourceGabc,
  }) {
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
  TextAlign textAnchor;
  int sourceIndex;
  String sourceGabc;
  String dominantBaseline = 'baseline';

  late String text;
  late List<TextSpan> spans;
  late TextStyleDefinition textType;
  late String cssClass;
  late int numLines;
  bool? rightAligned;
  bool needsLayout = false;
  DropCap? dropCap;
  bool? forceConnector;
  TextSpan? connectorSpan;
  double? resize;

  late double firstLineMaxWidth;

  String getCssClasses() => cssClass;
  Map<String, dynamic> getExtraStyleProperties(ChantContext ctxt) =>
      ctxt.baseTextStyle;

  void generateSpansFromText(ChantContext ctxt, String text) {
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    this.text = '';
    spans = [];

    if (text == '*' || text == '+' || text == '†') {
      final List<Map<String, dynamic>> properties = switch (text) {
        '*' => [ctxt.asteriskProperties],
        '+' => [ctxt.plusProperties],
        _ => [],
      };

      final mapped = ctxt.specialCharText(text);
      spans.add(TextSpan(mapped, properties, []));
      return;
    }

    final markupStack = <MarkupStackFrame>[];
    var spanStartIndex = 0;
    var newLineInNextSpan = 0;

    bool filterFrames(MarkupStackFrame frame, String? symbol) =>
        frame.symbol == symbol;

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
      spans.add(span);
      if (newLineInNextSpan > 0) {
        span.newLine = newLineInNextSpan;
        newLineInNextSpan = 0;
      }
    }

    final markupRegex = RegExp(
      r'(<br/?>)|<v>([\s\S]*?)(?:<\/v>|$)|(\*)(?=\s*\*|[^*]*(?:$|<v>))|(\+)|<sp>(?:(~)|('
      "'"
      r')?([ao]e|[æœaeiouy])|([arv])\/)<\/sp>|([arv])\/\.|([℣℟])\.?|(?:([*_^%])|<(\/)?([bceiuv]|ul|sc|font)(?:\s+(?:family="([^"]+)"|fill="([^"]+)"|class="([^"]+)"))*>)(?=(?:(.+?)(?:\11|<\/\13>))?)',
      caseSensitive: false,
    );
    final vTagRegex = RegExp(
      r"(\\grecross)|\{greextra\}\{([^}]*)\}|\{?(\\?')?(?:\\([ao]e|æœaeiouy))\}?",
      caseSensitive: false,
    );

    var openedAsterisk = false;

    void closeCurrentSpan(RegExpMatch match) {
      closeSpan(text.substring(spanStartIndex, match.start), spanStartIndex);
    }

    for (final match in markupRegex.allMatches(text)) {
      final newLine = match.group(1);
      final vTag = match.group(2);
      final asterisk = match.group(3);
      final plus = match.group(4);
      final tilde = match.group(5);
      final accent = match.group(6);
      final vowelLigature = match.group(7);
      final specialCharSp = match.group(8);
      final specialCharSlash = match.group(9);
      final specialCharVbar = match.group(10);
      final markupSymbol = match.group(11);
      final closingTag = match.group(12);
      var tagName = match.group(13);
      final family = match.group(14);
      final fill = match.group(15);
      final cssClass = match.group(16);
      final enclosedText = match.group(17);

      final specialChar = specialCharSp ?? specialCharSlash ?? specialCharVbar;

      if (newLine != null) {
        if (match.start > spanStartIndex) {
          closeCurrentSpan(match);
        }
        newLineInNextSpan++;
      } else if (vTag != null) {
        closeCurrentSpan(match);
        var lastIndex = 0;
        var iOffset = 0;
        for (final vMatch in vTagRegex.allMatches(vTag)) {
          if (lastIndex < vMatch.start) {
            closeSpan(
              vTag.substring(lastIndex, vMatch.start),
              match.start + lastIndex + iOffset,
            );
            iOffset = 3; // length of '<v>'
          }
          final grecross = vMatch.group(1);
          var greextra = vMatch.group(2);
          final vAccent = vMatch.group(3);
          final diphthong = vMatch.group(4);
          var char = '';
          if (diphthong != null) {
            char = makeLigature(diphthong);
            if (vAccent != null) char = addAccent(char);
            closeSpan(char, match.start + vMatch.start + iOffset);
          } else {
            if (grecross != null) {
              // grecross is just the command for the Cross:
              // set up greextra so it will get handled with it below:
              greextra = 'Cross';
            }
            char = glyphs.greextraGlyphs[greextra] ?? '';
            if (char.isNotEmpty) {
              closeSpan(char, match.start + vMatch.start + iOffset, {
                'font-family': 'greextra',
              });
            }
          }
          lastIndex = vMatch.end;
          iOffset = 3; // length of '<v>'
        }
        if (lastIndex < vTag.length) {
          closeSpan(
            vTag.substring(lastIndex),
            match.start + lastIndex + iOffset,
          );
        }
      } else if (asterisk != null) {
        closeCurrentSpan(match);
        // first check if it is just a symbol to close:
        if (markupStack.isNotEmpty && markupStack.last.symbol == asterisk) {
          markupStack.removeLast();
        } else {
          closeSpan(
            ctxt.specialCharText(asterisk),
            match.start,
            ctxt.asteriskProperties,
          );
        }
      } else if (plus != null) {
        closeCurrentSpan(match);
        closeSpan(ctxt.specialCharText(plus), match.start, ctxt.plusProperties);
      } else if (tilde != null) {
        closeCurrentSpan(match);
        closeSpan('∼', match.start);
      } else if (vowelLigature != null) {
        var vowel = makeLigature(vowelLigature);
        if (accent != null) vowel = addAccent(vowel);
        closeCurrentSpan(match);
        closeSpan(vowel, match.start);
      } else if (specialChar != null) {
        closeCurrentSpan(match);
        closeSpan(
          ctxt.textBeforeSpecialChar +
              ctxt.specialCharText(specialChar) +
              ctxt.textAfterSpecialChar,
          match.start,
          ctxt.specialCharProperties,
        );
      } else {
        // otherwise we're dealing with matching markup delimeters
        if (markupSymbol == '*') {
          // we are only strict with the asterisk, because there are cases
          // when it needs to be displayed rather than count as a markup
          // symbol
          if (enclosedText != null &&
              RegExp(r'[^\s*]').hasMatch(enclosedText)) {
            openedAsterisk = true;
          } else if (openedAsterisk) {
            openedAsterisk = false;
          } else {
            // actually use the asterisk, since it doesn't have a matching
            // closing asterisk
            continue;
          }
        }
        if (markupSymbol != null) {
          tagName = ctxt.markupSymbolDictionary[markupSymbol];
          if (markupStack.isNotEmpty &&
              markupStack.last.tagName == tagName &&
              markupStack.last.symbol == markupSymbol) {
            if (closingTag != null) {
              closeCurrentSpan(match);
              markupStack.removeLast();
            }
            // otherwise: matching symbol on top of stack but not a closing
            // tag — fall through to group open below
            else {
              closeCurrentSpan(match);
              final extraProperties = <String, dynamic>{};
              if (family != null) extraProperties['font-family'] = family;
              if (fill != null) extraProperties['fill'] = fill;
              if (cssClass != null) extraProperties['class'] = cssClass;
              markupStack.add(
                MarkupStackFrame.createStackFrame(
                  ctxt,
                  tagName!,
                  match.start,
                  extraProperties,
                  markupSymbol,
                ),
              );
            }
          } else if (markupStack.isNotEmpty &&
              markupStack.last.tagName == tagName) {
            if (closingTag != null) {
              closeCurrentSpan(match);
              markupStack.removeLast();
            }
          } else if (markupStack
              .where((f) => filterFrames(f, markupSymbol))
              .isNotEmpty) {
            // trying to open a recursive group (or forgot to close a previous
            // group). In either case, we just unwind to the previous stack
            // frame
            spanStartIndex = markupStack.last.startIndex;
            markupStack.removeLast();
            continue;
          } else {
            closeCurrentSpan(match);
            if (closingTag != null) {
              // out of order group close:
              final index = markupStack.indexWhere(
                (frame) => frame.tagName == tagName,
              );
              if (index >= 0) {
                markupStack.removeRange(index, index + 1);
              }
            } else {
              // group open
              final extraProperties = <String, dynamic>{};
              if (family != null) extraProperties['font-family'] = family;
              if (fill != null) extraProperties['fill'] = fill;
              if (cssClass != null) extraProperties['class'] = cssClass;
              markupStack.add(
                MarkupStackFrame.createStackFrame(
                  ctxt,
                  tagName!,
                  match.start,
                  extraProperties,
                  markupSymbol,
                ),
              );
            }
          }
        } else if (tagName != null) {
          if (markupStack.isNotEmpty && markupStack.last.tagName == tagName) {
            if (closingTag != null) {
              closeCurrentSpan(match);
              markupStack.removeLast();
            }
          } else if (markupStack
              .where((f) => filterFrames(f, null))
              .isNotEmpty) {
            spanStartIndex = markupStack.last.startIndex;
            markupStack.removeLast();
            continue;
          } else {
            closeCurrentSpan(match);
            if (closingTag != null) {
              final index = markupStack.indexWhere(
                (frame) => frame.tagName == tagName,
              );
              if (index >= 0) {
                markupStack.removeRange(index, index + 1);
              }
            } else {
              final extraProperties = <String, dynamic>{};
              if (family != null) extraProperties['font-family'] = family;
              if (fill != null) extraProperties['fill'] = fill;
              if (cssClass != null) extraProperties['class'] = cssClass;
              markupStack.add(
                MarkupStackFrame.createStackFrame(
                  ctxt,
                  tagName,
                  match.start,
                  extraProperties,
                  '',
                ),
              );
            }
          }
        }
      }

      // advance the start index past the current markup
      spanStartIndex = match.end;
    }

    // if we finished matches, and there is still some text left,
    // or if we haven't generated any spans yet, create one final run
    if (spanStartIndex < text.length || spans.isEmpty) {
      closeSpan(text.substring(spanStartIndex), spanStartIndex);
    }
  }

  double measureSubstring(ChantContext ctxt, [int? length]) =>
      ctxt.textMeasurer.measureSubstring(this, ctxt, length);

  void recalculateMetrics(ChantContext ctxt, [bool resetNewLines = true]) {
    if (resetNewLines) {
      for (final span in spans) {
        span.xOffset = null;
        if (span.newLine > 0) {
          span.newLine = 0;
          span.text = " ${span.text}";
        }
      }
    }

    bounds = bounds.copyWith(x: 0, y: 0);
    origin = core.Point(0, origin.y);

    final bbox = ctxt.textMeasurer.measureTextBounds(this, ctxt);
    bounds = bounds.copyWith(width: bbox.width, height: bbox.height);
    origin = core.Point(-bbox.x, -bbox.y);

    numLines = spans.fold(1, (acc, s) => acc + s.newLine);
  }

  void setMaxWidth(
    ChantContext ctxt,
    double maxWidth, [
    double firstLineMaxWidth = -1,
  ]) {
    if (spans.any((s) => s.newLine > 0)) {
      recalculateMetrics(ctxt);
    }
    if (bounds.width > maxWidth) {
      final percentage = maxWidth / bounds.width;
      if (this is Lyric && percentage >= 0.85) {
        resize = percentage;
      } else {
        if (firstLineMaxWidth < 0) firstLineMaxWidth = maxWidth;
        this.firstLineMaxWidth = firstLineMaxWidth;
        RegExpMatch? lastMatch;
        final regex = RegExp(r'\s+|$', multiLine: true);
        double max = firstLineMaxWidth;
        for (final match in regex.allMatches(text)) {
          if (lastMatch == null || match.start > lastMatch.start) {
            var width = measureSubstring(ctxt, match.start);
            if (width > max && lastMatch != null) {
              var spanIndex = 0, length = 0;
              while (length < lastMatch.start && spanIndex < spans.length) {
                var span = spans[spanIndex++];
                length += span.text.length + span.newLine;
              }
              if (length > lastMatch.start || spanIndex >= spans.length) {
                var span = spans[--spanIndex];
                length -= span.text.length;
              }
              var splitSpan = spans[spanIndex];
              var textLeft = splitSpan.text.substring(
                0,
                lastMatch.start - length,
              );

              rightAligned =
                  max == firstLineMaxWidth && firstLineMaxWidth != maxWidth;
              final newSpans = [
                TextSpan(
                  textLeft,
                  splitSpan.propertyArray,
                  splitSpan.activeTags,
                ),
              ];
              if (lastMatch.start + lastMatch[0]!.length - length <
                  splitSpan.text.length) {
                final textRight = splitSpan.text.substring(
                  lastMatch.start + lastMatch[0]!.length - length,
                );
                newSpans.add(
                  TextSpan(
                    textRight,
                    splitSpan.propertyArray,
                    splitSpan.activeTags,
                    0,
                    {'newLine': 1},
                  ),
                );
              } else if (spans.length > spanIndex + 1) {
                spans[spanIndex + 1].newLine = 1;
              }
              spans.replaceRange(spanIndex, spanIndex + 1, newSpans);
              needsLayout = true;
              max = maxWidth;
              if (match.start == text.length ||
                  measureSubstring(ctxt) <= maxWidth) {
                break;
              }
              width = 0;
            }
            lastMatch = match;
          }
        }
      }
      recalculateMetrics(ctxt, false);
    }
  }

  Map<String, dynamic> getSvgProps() {
    return {
      'data-source-index': sourceIndex,
      'x': bounds.x,
      'y': bounds.y,
      'class': getCssClasses().trim(),
      'text-anchor': switch (textAnchor) {
        .center => 'middle',
        _ => textAnchor.name,
      },
    };
  }

  Map<String, dynamic> getSpanOptions(
    TextSpan span,
    ChantContext ctxt, [
    bool useStyleObject = false,
  ]) {
    final options = <String, dynamic>{
      'data-source-index': span.index,
      'class': span.properties['class'],
      'style': useStyleObject
          ? span.properties
          : getCssForProperties(span.properties),
    };
    if (span.newLine > 0) {
      final xOffset = span.xOffset ?? 0.0;
      options['dy'] = '${1.1 * span.newLine}em';
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
    final options = getSvgProps();
    final extraStyleProperties = getExtraStyleProperties(ctxt);
    if (extraStyleProperties['class'] != null) {
      options['class'] = '${extraStyleProperties['class']} ${options['class']}';
    }
    if (ctxt.stylingMode == .attributes) {
      final ts = ctxt.textStyles;
      options.addAll({
        for (final c in (options['class'] as String).split(" "))
          if (ts.containsKey(c)) ...{
            'fill': (ts[c]['color'] as Color? ?? ctxt.theme.textColor)
                .toSvgString(),
            'font-family': ts[c]['font'] ?? 'serif',
            'font-size': ts[c]['size'] ?? 16,
          },
        for (final e in extraStyleProperties.entries)
          e.key: e.value is Color ? (e.value as Color).toSvgString() : e.value,
      });
    } else {
      options['style'] = getCssForProperties(extraStyleProperties);
    }
    return QuickSvg.createNode('text', options, [
      for (final span in spans)
        QuickSvg.createNode('tspan', getSpanOptions(span, ctxt), span.text),
    ]);
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
  void draw(ChantContext ctxt) {
    final canvas = ctxt.canvas;
    double translateWidth = 0.0;
    final alignOffset = switch (textAnchor) {
      .center => bounds.width / 2,
      .right || .end => bounds.width,
      _ => 0,
    };

    canvas.save();

    final properties = <String, dynamic>{
      ...getExtraStyleProperties(ctxt),
      'base-font-family': fontFamily(ctxt),
      'base-font-size': fontSize(ctxt),
      'fill': ?ctxt.textStyles[cssClass]!['fill'],
    };
    for (final span in spans) {
      final xOffset = span.xOffset ?? 0.0;
      if (span.newLine > 0) {
        canvas.translate(
          translateWidth + xOffset,
          fontSize(ctxt) * span.newLine,
        );
        translateWidth = -xOffset;
      } else if (xOffset != 0.0) {
        canvas.translate(translateWidth + xOffset, 0);
        translateWidth = -xOffset;
      }

      final paragraph = span.buildParagraph(
        ctxt,
        {...properties, ...span.properties},
        textAnchor,
        resize,
      );
      paragraph.layout(ParagraphConstraints(width: bounds.width));
      canvas.drawParagraph(paragraph, Offset(bounds.x - alignOffset, bounds.y));

      final metricsWidth = paragraph.maxIntrinsicWidth;
      translateWidth -= metricsWidth;
      canvas.translate(metricsWidth, 0);
    }
    canvas.restore();
  }

  @override
  core.Rect get boundsForHitTest => switch (textAnchor) {
    .center => bounds.copyWith(x: bounds.x - bounds.width / 2),
    .end => bounds.copyWith(x: bounds.x - bounds.width),
    _ => bounds,
  };

  String toGabcString() => spans.map((s) => s.toGabcString()).join('');
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
  int newLine = 0;

  Map<String, dynamic> get properties {
    final result = <String, dynamic>{};
    for (final props in propertyArray) {
      result.addAll(props);
    }
    if (xOffset != null) result['xOffset'] = xOffset;
    if (newLine > 0) result['newLine'] = newLine;
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
    final builder =
        ParagraphBuilder(
            ParagraphStyle(
              textAlign: textAlign,
              textDirection: TextDirection.ltr,
            ),
          )
          ..pushStyle(getTextStyle(extraProps, ctxt, resize))
          ..addText(text);

    return builder.build();
  }

  static TextStyle getTextStyle(
    Map<String, dynamic> props,
    ChantContext ctxt,
    double? resize,
  ) {
    final fontSize = _parseCssFontSize(
      props['font-size'],
      props['base-font-size'],
    );
    final fontFamily = (props['font-family'] ?? props['base-font-family'])
        .toString()
        .split(RegExp(", ?"))
        .map((f) => f.replaceAll(RegExp(r"^'|'$"), ''))
        .toList();
    return TextStyle(
      color: _colorFromCss(props['fill'], ctxt.theme.textColor),
      fontFamilyFallback: fontFamily,
      fontSize: fontSize * (resize ?? 1),
      height: props['line-height'],
      fontStyle: props['font-style'] == 'italic'
          ? FontStyle.italic
          : FontStyle.normal,
      fontWeight: props['font-weight'] == 'bold'
          ? FontWeight.bold
          : FontWeight.normal,
      fontFeatures: [
        if (props['font-variant'] == 'small-caps') FontFeature.enable('smcp'),
      ],
    );
  }

  static Color _colorFromCss(dynamic fill, Color defaultColor) {
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

  static double _parseCssFontSize(dynamic fontSizeValue, double baseFontSize) {
    if (fontSizeValue is String && fontSizeValue.endsWith('%')) {
      final percent =
          double.tryParse(fontSizeValue.replaceAll('%', '')) ?? 100.0;
      return baseFontSize * percent / 100.0;
    }
    if (fontSizeValue is num) return fontSizeValue.toDouble();
    return baseFontSize;
  }

  String toGabcString() {
    final buf = StringBuffer();
    for (var t in activeTags) {
      buf.write('<$t>');
    }
    buf.write(text);
    for (var t in activeTags) {
      buf.write('</$t>');
    }
    return buf.toString();
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

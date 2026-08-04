import 'dart:ui';

import 'chant_context.dart';

class BaseTextStyle {
  final String font;
  final double size;
  final Map<String, dynamic> baseStyle;

  const BaseTextStyle({
    required this.font,
    required this.size,
    this.baseStyle = const {},
  });
}

class TextStyleDefinition {
  const TextStyleDefinition({
    this.display = '',
    this.cssClass = '',
    this.font,
    this.defaultSize,
    this.size,
  });
  final String display;
  final String cssClass;
  final String? font;
  final double Function(double size)? defaultSize;
  final double Function(ChantContext ctxt)? size;
}

class ChantTheme {
  final BaseTextStyle baseTextStyle;
  late final TextStyleDefinition supertitle;
  late final TextStyleDefinition title;
  late final TextStyleDefinition subtitle;
  late final TextStyleDefinition leftRight;
  late final TextStyleDefinition annotation;
  late final TextStyleDefinition dropCap;
  late final TextStyleDefinition aboveLine;
  late final TextStyleDefinition choralSign;
  late final TextStyleDefinition lyric;
  late final TextStyleDefinition translation;
  final Color textColor;
  final Color rubricColor;
  final Color neumeLineColor;
  final Color staffLineColor;
  final Color dividerLineColor;
  final double minLedgerSeparation;
  final double minSpaceAboveStaff;
  final double minSpaceBelowStaff;
  final double spaceBetweenSystems;

  ChantTheme({
    this.baseTextStyle = defaultBaseTextStyle,
    this.textColor = ChantColors.nigric,
    this.rubricColor = ChantColors.rubric,
    this.neumeLineColor = ChantColors.nigric,
    this.staffLineColor = ChantColors.rubric,
    this.dividerLineColor = ChantColors.nigric,
    this.minLedgerSeparation = kDefaultMinLedgerSeparation,
    this.minSpaceAboveStaff = kDefaultMinSpaceAboveStaff,
    this.minSpaceBelowStaff = kDefaultMinSpaceBelowStaff,
    this.spaceBetweenSystems = kDefaultSpaceBetweenSystems,
    TextStyleDefinition? supertitle,
    TextStyleDefinition? title,
    TextStyleDefinition? subtitle,
    TextStyleDefinition? leftRight,
    TextStyleDefinition? annotation,
    TextStyleDefinition? dropCap,
    TextStyleDefinition? aboveLine,
    TextStyleDefinition? choralSign,
    TextStyleDefinition? lyric,
    TextStyleDefinition? translation,
  }) : supertitle = supertitle ?? defaultTextStyles['supertitle']!,
       title = title ?? defaultTextStyles['title']!,
       subtitle = title ?? defaultTextStyles['subtitle']!,
       leftRight = title ?? defaultTextStyles['leftRight']!,
       annotation = title ?? defaultTextStyles['annotation']!,
       dropCap = title ?? defaultTextStyles['dropCap']!,
       aboveLine = title ?? defaultTextStyles['al']!,
       choralSign = title ?? defaultTextStyles['choralSign']!,
       lyric = title ?? defaultTextStyles['lyric']!,
       translation = title ?? defaultTextStyles['translation']!;

  Map<String, TextStyleDefinition> get textStyles => {
    'supertitle': supertitle,
    'title': title,
    'subtitle': subtitle,
    'leftRight': leftRight,
    'annotation': annotation,
    'dropCap': dropCap,
    'al': aboveLine,
    'choralSign': choralSign,
    'lyric': lyric,
    'translation': translation,
  };
}

const double kDefaultMinLedgerSeparation = 2;
const double kDefaultMinSpaceAboveStaff = 2;
const double kDefaultMinSpaceBelowStaff = 1;
const double kDefaultSpaceBetweenSystems = 1.5;

const defaultBaseTextStyle = BaseTextStyle(
  font: "'Palatino Linotype', 'Book Antiqua', Palatino, serif",
  size: 16,
);

class ChantColors {
  static const Color nigric = Color(0xFF000000);
  static const Color rubric = Color(0xFFDD0000);
}

final Map<String, TextStyleDefinition> defaultTextStyles = {
  'supertitle': TextStyleDefinition(
    display: 'Supertitle',
    cssClass: 'supertitle',
    defaultSize: (size) => (size * 7) / 6, // 14pt
  ),
  'title': TextStyleDefinition(
    display: 'Title',
    cssClass: 'title',
    defaultSize: (size) => (size * 3) / 2, // 18pt
  ),
  'subtitle': TextStyleDefinition(
    display: 'Subtitle',
    cssClass: 'subtitle',
    defaultSize: (size) => size, // 12pt
  ),
  'leftRight': TextStyleDefinition(
    display: 'Left / Right Text',
    cssClass: 'textLeftRight',
    defaultSize: (size) => size * 0.9,
  ),
  'annotation': TextStyleDefinition(
    display: 'Annotation',
    cssClass: 'annotation',
    defaultSize: (size) => (size * 2) / 3,
  ),
  'dropCap': TextStyleDefinition(
    display: 'Drop Cap',
    cssClass: 'dropCap',
    defaultSize: (size) => size * 4,
  ),
  'al': TextStyleDefinition(
    display: 'Above Staff',
    cssClass: 'aboveLinesText',
    defaultSize: (size) => size,
  ),
  'choralSign': TextStyleDefinition(
    display: 'Choral Sign',
    cssClass: 'choralSign',
    size: (ctxt) => ctxt.staffInterval * 1.5,
  ),
  'lyric': TextStyleDefinition(
    display: 'Lyric',
    cssClass: 'lyric',
    defaultSize: (size) => size * 0.9,
  ),
  'translation': TextStyleDefinition(
    display: 'Translation',
    cssClass: 'translation',
    defaultSize: (size) => size * 0.75,
  ),
};

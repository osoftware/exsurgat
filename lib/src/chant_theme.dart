import 'dart:ui';

import 'chant_context.dart';

class BaseTextStyle {
  /// Font list using CSS syntax.
  final String font;
  final double size;

  /// Additional CSS properties.
  final Map<String, dynamic> baseStyle;

  const BaseTextStyle({
    required this.font,
    required this.size,
    this.baseStyle = const {},
  });
}

class TextStyleDefinition {
  const TextStyleDefinition({
    this.font,
    this.relativeSize,
    this.size,
    this.color,
  }) : assert(
         (relativeSize != null) ^ (size != null),
         'Can\'t define relativeSize and size at the same time',
       );

  /// Font list using CSS syntax. Overrides font defined in baseTextStyle.
  final String? font;

  /// Calculates the font size relative to size defined in baseFontStyle.
  final double Function(double size)? relativeSize;

  /// Calculates the font size from ChantContext if [relativeSize] is not provided.
  final double Function(ChantContext ctxt)? size;

  /// Text color. Overrides [ChantTheme.textColor] but not [ChantTheme.rubricColor].
  final Color? color;
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
  final Color neumeColor;
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
    this.neumeColor = ChantColors.nigric,
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
       subtitle = subtitle ?? defaultTextStyles['subtitle']!,
       leftRight = leftRight ?? defaultTextStyles['leftRight']!,
       annotation = annotation ?? defaultTextStyles['annotation']!,
       dropCap = dropCap ?? defaultTextStyles['dropCap']!,
       aboveLine = aboveLine ?? defaultTextStyles['al']!,
       choralSign = choralSign ?? defaultTextStyles['choralSign']!,
       lyric = lyric ?? defaultTextStyles['lyric']!,
       translation = translation ?? defaultTextStyles['translation']!;

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

  static final kDefaultTheme = ChantTheme();
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
  'supertitle': TextStyleDefinition(relativeSize: (size) => (size * 7) / 6),
  'title': TextStyleDefinition(relativeSize: (size) => (size * 3) / 2),
  'subtitle': TextStyleDefinition(relativeSize: (size) => size),
  'leftRight': TextStyleDefinition(relativeSize: (size) => size * 0.9),
  'annotation': TextStyleDefinition(relativeSize: (size) => (size * 2) / 3),
  'dropCap': TextStyleDefinition(relativeSize: (size) => size * 4),
  'al': TextStyleDefinition(relativeSize: (size) => size),
  'choralSign': TextStyleDefinition(size: (ctxt) => ctxt.staffInterval * 1.5),
  'lyric': TextStyleDefinition(relativeSize: (size) => size * 0.9),
  'translation': TextStyleDefinition(relativeSize: (size) => size * 0.75),
};

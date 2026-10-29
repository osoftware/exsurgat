import 'dart:ui';

import 'package:exsurgat/src/core.dart';
import 'package:flutter/foundation.dart';

import 'chant_context.dart';
import 'drawing.dart';
import 'gabc.dart';

/// Default style for all texts, overriden by [TextStyleDefinition] for specific
/// text classes.
class BaseTextStyle {
  /// Font list using CSS syntax.
  final String font;

  /// Font size.
  final Scalar size;

  /// Font weight.
  final FontWeight? fontWeight;

  /// FontStyle.
  final FontStyle? fontStyle;

  /// Font features.
  final List<FontFeature> features;

  const BaseTextStyle({
    required this.font,
    required this.size,
    this.fontWeight,
    this.fontStyle,
    this.features = const [],
  });

  /// Serialized representation of this base text style.
  Map<String, String> toMap() => {
    'font': font,
    'size': '$size',
    'font-weight': ?fontWeight?.toSvgString(),
    'font-style': ?fontStyle?.toSvgString(),
    if (features.isNotEmpty)
      'font-variant': features.map((f) => f.toSvgString()).join(' '),
  };

  factory BaseTextStyle.fromMap(Map<String, dynamic> map) {
    return BaseTextStyle(
      font: map['font'] as String? ?? kDefaultBaseTextStyle.font,
      size: Scalar.tryParse('${map['size']}') ?? kDefaultBaseTextStyle.size,
      fontWeight: FontWeightSvg.tryParse(map['font-weight']),
      fontStyle: FontStyleSvg.tryParse(map['font-style']),
      features: FontFeatureSvg.parseVariants(map['font-variant']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BaseTextStyle &&
      font == other.font &&
      size == other.size &&
      fontWeight == other.fontWeight &&
      fontStyle == other.fontStyle &&
      listEquals(features, other.features);

  @override
  int get hashCode => Object.hash(
    font,
    size,
    fontWeight,
    fontStyle,
    Object.hashAllUnordered(features),
  );
}

/// Splits a CSS font list into list of family names.
List<String> parseFontFallback(String css) => css
    .split(RegExp(", ?"))
    .map((f) => f.replaceAll(RegExp(r"^'|'$"), ''))
    .toList();

/// Base class for text-size resolution strategies.
sealed class FontSize {
  const FontSize();

  factory FontSize.relative(double factor) = RelativeFontSize;

  factory FontSize.staffInterval(double multiplier) = StaffIntervalFontSize;

  factory FontSize.absolute(Scalar size) = AbsoluteFontSize;

  /// Resolves the concrete font size.
  double resolve(double baseSize, ChantContext ctxt);

  static FontSize? tryParse(String text) {
    if (text.endsWith('%')) {
      final value = text.substring(0, text.length - 1);
      return FontSize.relative(double.parse(value) / 100);
    }
    if (text.endsWith('#')) {
      final value = text.substring(0, text.length - 1);
      return FontSize.staffInterval(double.parse(value));
    }
    return Scalar.tryParse(text).bind(FontSize.absolute);
  }
}

/// Font size as a factor of the base text style size.
class RelativeFontSize extends FontSize {
  final double factor;

  const RelativeFontSize(this.factor);

  @override
  double resolve(double baseSize, ChantContext ctxt) => baseSize * factor;

  @override
  bool operator ==(Object other) =>
      other is RelativeFontSize && factor == other.factor;

  @override
  int get hashCode => factor.hashCode;

  @override
  String toString() => '${(factor * 100).toInt()}%';
}

/// Font size derived from the staff interval of the [ChantContext].
class StaffIntervalFontSize extends FontSize {
  final double multiplier;

  const StaffIntervalFontSize(this.multiplier);

  @override
  double resolve(double baseSize, ChantContext ctxt) =>
      ctxt.staffInterval * multiplier;

  @override
  bool operator ==(Object other) =>
      other is StaffIntervalFontSize && multiplier == other.multiplier;

  @override
  int get hashCode => multiplier.hashCode;

  @override
  String toString() => '$multiplier#';
}

/// Fixed font size, independent of context.
class AbsoluteFontSize extends FontSize {
  final Scalar size;

  const AbsoluteFontSize(this.size);

  @override
  double resolve(double baseSize, ChantContext ctxt) => size.deviceIndependent;

  @override
  bool operator ==(Object other) =>
      other is AbsoluteFontSize && size == other.size;

  @override
  int get hashCode => size.hashCode;

  @override
  String toString() => size.toString();
}

/// Style for a text class.
class TextStyleDefinition {
  const TextStyleDefinition({
    this.font,
    this.fontWeight,
    this.fontStyle,
    this.size,
    this.color,
    this.features = const [],
  });

  factory TextStyleDefinition.fromMap(Map<String, dynamic> map) =>
      TextStyleDefinition(
        font: map['font'] as String?,
        size: FontSize.tryParse(map['size']),
        fontWeight: FontWeightSvg.tryParse(map['font-weight']),
        fontStyle: FontStyleSvg.tryParse(map['font-style']),
        features: FontFeatureSvg.parseVariants(map['font-variant']),
        color: parseColor(map['color']),
      );

  /// Font list using CSS syntax. Overrides font defined in baseTextStyle.
  final String? font;

  /// Font weight.
  final FontWeight? fontWeight;

  /// FontStyle.
  final FontStyle? fontStyle;

  /// Size resolution strategy. Falls back to the base text style size.
  final FontSize? size;

  /// Text color. Overrides [ChantTheme.textColor] but not [ChantTheme.rubricColor].
  final Color? color;

  /// Font features.
  final List<FontFeature> features;

  /// Serialized representation of this text style.
  Map<String, String> toMap() => {
    'font': ?font,
    'size': ?size?.toString(),
    'color': ?color?.toSvgString(),
    'font-weight': ?fontWeight?.toSvgString(),
    'font-style': ?fontStyle?.toSvgString(),
    if (features.isNotEmpty)
      'font-variant': features.map((f) => f.toSvgString()).join(' '),
  };

  @override
  bool operator ==(Object other) =>
      other is TextStyleDefinition &&
      font == other.font &&
      size == other.size &&
      fontWeight == other.fontWeight &&
      fontStyle == other.fontStyle &&
      listEquals(features, other.features) &&
      color == other.color;

  @override
  int get hashCode => Object.hash(
    font,
    size,
    fontWeight,
    fontStyle,
    Object.hashAllUnordered(features),
    color,
  );
}

extension FontWeightSvg on FontWeight? {
  String? toSvgString() => switch (this) {
    null => null,
    FontWeight.normal => null,
    FontWeight.bold => 'bold',
    FontWeight(:final value) => value.toString(),
  };

  static FontWeight? tryParse(String? value) => switch (value) {
    null => null,
    'normal' => FontWeight.normal,
    'bold' => FontWeight.bold,
    _ => int.tryParse(value).bind(FontWeight.new),
  };
}

extension FontStyleSvg on FontStyle? {
  String? toSvgString() => switch (this) {
    null => null,
    FontStyle.normal => null,
    FontStyle.italic => 'italic',
  };

  static FontStyle? tryParse(String? value) => switch (value) {
    'normal' => .normal,
    'italic' => .italic,
    _ => null,
  };
}

extension FontFeatureSvg on FontFeature? {
  String toSvgString() => switch (this?.feature) {
    'smcp' => 'small-caps',
    'hist' => 'historical-forms',
    'hlig' => 'historical-ligatures',
    'calt' => 'contextual',
    _ => '',
  };

  static List<FontFeature> parseVariants(String? value) => switch (value) {
    null => [],
    final s =>
      s
          .split(' ')
          .map(
            (feature) => switch (feature) {
              'small-caps' => FontFeature('smcp'),
              'historical-forms' => FontFeature.historicalForms(),
              'historical-ligatures' => FontFeature.historicalLigatures(),
              'contextual' => FontFeature.contextualAlternates(),
              _ => null,
            },
          )
          .whereType<FontFeature>()
          .toList(),
  };
}

/// All coloring, spacing and text styling that can be configured for a chant rendering.
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
  final Color selectionColor;
  final double minLedgerSeparation;
  final double minSpaceAboveStaff;
  final double minSpaceBelowStaff;
  final double spaceBetweenSystems;

  /// Creates a new theme. Unspecified parameters fall back to the default theme.
  ChantTheme({
    this.baseTextStyle = kDefaultBaseTextStyle,
    this.textColor = ChantColors.nigric,
    this.rubricColor = ChantColors.rubric,
    this.neumeColor = ChantColors.nigric,
    this.staffLineColor = ChantColors.rubric,
    this.dividerLineColor = ChantColors.nigric,
    this.selectionColor = ChantColors.caeruleus,
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
  }) : supertitle = supertitle ?? kDefaultTextStyles['supertitle']!,
       title = title ?? kDefaultTextStyles['title']!,
       subtitle = subtitle ?? kDefaultTextStyles['subtitle']!,
       leftRight = leftRight ?? kDefaultTextStyles['leftRight']!,
       annotation = annotation ?? kDefaultTextStyles['annotation']!,
       dropCap = dropCap ?? kDefaultTextStyles['dropCap']!,
       aboveLine = aboveLine ?? kDefaultTextStyles['al']!,
       choralSign = choralSign ?? kDefaultTextStyles['choralSign']!,
       lyric = lyric ?? kDefaultTextStyles['lyric']!,
       translation = translation ?? kDefaultTextStyles['translation']!;

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

  @override
  bool operator ==(Object other) =>
      other is ChantTheme &&
      baseTextStyle == other.baseTextStyle &&
      textColor == other.textColor &&
      rubricColor == other.rubricColor &&
      neumeColor == other.neumeColor &&
      staffLineColor == other.staffLineColor &&
      dividerLineColor == other.dividerLineColor &&
      selectionColor == other.selectionColor &&
      minLedgerSeparation == other.minLedgerSeparation &&
      minSpaceAboveStaff == other.minSpaceAboveStaff &&
      minSpaceBelowStaff == other.minSpaceBelowStaff &&
      spaceBetweenSystems == other.spaceBetweenSystems &&
      supertitle == other.supertitle &&
      title == other.title &&
      subtitle == other.subtitle &&
      leftRight == other.leftRight &&
      annotation == other.annotation &&
      dropCap == other.dropCap &&
      aboveLine == other.aboveLine &&
      choralSign == other.choralSign &&
      lyric == other.lyric &&
      translation == other.translation;

  @override
  int get hashCode => Object.hashAll([
    baseTextStyle,
    textColor,
    rubricColor,
    neumeColor,
    staffLineColor,
    dividerLineColor,
    selectionColor,
    minLedgerSeparation,
    minSpaceAboveStaff,
    minSpaceBelowStaff,
    spaceBetweenSystems,
    supertitle,
    title,
    subtitle,
    leftRight,
    annotation,
    dropCap,
    aboveLine,
    choralSign,
    lyric,
    translation,
  ]);

  /// Updates [header] with this theme's values, compatible with [GabcHeader].
  ///
  /// Values that differ from the default theme are set; values that equal the
  /// default are removed from the header.
  void updateHeader(GabcHeader header) {
    header.put(
      'text-color',
      textColor.toSvgString(),
      kDefaultTheme.textColor.toSvgString(),
    );
    header.put(
      'rubric-color',
      rubricColor.toSvgString(),
      kDefaultTheme.rubricColor.toSvgString(),
    );
    header.put(
      'neume-color',
      neumeColor.toSvgString(),
      kDefaultTheme.neumeColor.toSvgString(),
    );
    header.put(
      'staff-line-color',
      staffLineColor.toSvgString(),
      kDefaultTheme.staffLineColor.toSvgString(),
    );
    header.put(
      'divider-line-color',
      dividerLineColor.toSvgString(),
      kDefaultTheme.dividerLineColor.toSvgString(),
    );
    header.put(
      'selection-color',
      selectionColor.toSvgString(),
      kDefaultTheme.selectionColor.toSvgString(),
    );
    header.put(
      'min-ledger-separation',
      '$minLedgerSeparation',
      '${kDefaultTheme.minLedgerSeparation}',
    );
    header.put(
      'min-space-above-staff',
      '$minSpaceAboveStaff',
      '${kDefaultTheme.minSpaceAboveStaff}',
    );
    header.put(
      'min-space-below-staff',
      '$minSpaceBelowStaff',
      '${kDefaultTheme.minSpaceBelowStaff}',
    );
    header.put(
      'space-between-systems',
      '$spaceBetweenSystems',
      '${kDefaultTheme.spaceBetweenSystems}',
    );

    header.put(
      'base-text-style.font',
      baseTextStyle.font,
      kDefaultTheme.baseTextStyle.font,
    );
    header.put(
      'base-text-style.size',
      '${baseTextStyle.size}',
      '${kDefaultTheme.baseTextStyle.size}',
    );

    if (baseTextStyle == kDefaultTheme.baseTextStyle) {
      header.removeAll('base-text-style.');
    }

    final kDefaultStyles = kDefaultTheme.textStyles;
    textStyles.forEach((name, style) {
      if (style == kDefaultStyles[name]) {
        header.removeAll('text-style.$name.');
        return;
      }
      style.toMap().forEach(
        (property, value) => header['text-style.$name.$property'] = value,
      );
    });
  }

  /// Deserializes a theme from header values.
  factory ChantTheme.fromGabcHeader(GabcHeader header) {
    final values = header.toMap();
    final base = <String, dynamic>{};
    values.forEach((key, value) {
      if (key.startsWith('base-text-style.')) {
        base[key.substring('base-text-style.'.length)] = value;
      }
    });
    final baseTextStyle = base.isEmpty
        ? kDefaultBaseTextStyle
        : BaseTextStyle.fromMap(base);

    final styles = <String, Map<String, dynamic>>{};
    values.forEach((key, value) {
      final match = RegExp(
        r'^text-style\.([a-zA-Z]+)\.([a-zA-Z-]+)$',
      ).firstMatch(key);
      if (match == null) return;
      styles.putIfAbsent(match.group(1)!, () => {})[match.group(2)!] = value;
    });

    TextStyleDefinition style(String name) {
      final map = styles[name];
      return map == null
          ? kDefaultTextStyles[name] ?? const TextStyleDefinition()
          : TextStyleDefinition.fromMap(map);
    }

    return ChantTheme(
      baseTextStyle: baseTextStyle,
      textColor: header.readColor('text-color', ChantColors.nigric),
      rubricColor: header.readColor('rubric-color', ChantColors.rubric),
      neumeColor: header.readColor('neume-color', ChantColors.nigric),
      staffLineColor: header.readColor('staff-line-color', ChantColors.rubric),
      dividerLineColor: header.readColor(
        'divider-line-color',
        ChantColors.nigric,
      ),
      selectionColor: header.readColor(
        'selection-color',
        ChantColors.caeruleus,
      ),
      minLedgerSeparation: header.readDouble(
        'min-ledger-separation',
        kDefaultMinLedgerSeparation,
      ),
      minSpaceAboveStaff: header.readDouble(
        'min-space-above-staff',
        kDefaultMinSpaceAboveStaff,
      ),
      minSpaceBelowStaff: header.readDouble(
        'min-space-below-staff',
        kDefaultMinSpaceBelowStaff,
      ),
      spaceBetweenSystems: header.readDouble(
        'space-between-systems',
        kDefaultSpaceBetweenSystems,
      ),
      supertitle: style('supertitle'),
      title: style('title'),
      subtitle: style('subtitle'),
      leftRight: style('leftRight'),
      annotation: style('annotation'),
      dropCap: style('dropCap'),
      aboveLine: style('al'),
      choralSign: style('choralSign'),
      lyric: style('lyric'),
      translation: style('translation'),
    );
  }

  static final kDefaultTheme = ChantTheme();
}

const double kDefaultMinLedgerSeparation = 2;
const double kDefaultMinSpaceAboveStaff = 2;
const double kDefaultMinSpaceBelowStaff = 1;
const double kDefaultSpaceBetweenSystems = 1.5;

const kDefaultBaseTextStyle = BaseTextStyle(
  font: "'Palatino Linotype', 'Book Antiqua', Palatino, serif",
  size: Scalar(16),
);

class ChantColors {
  /// Standard color for texts to read.
  static const Color nigric = Color(0xFF000000);

  /// Standart color for texts to obey.
  static const Color rubric = Color(0xFFDD0000);

  /// Selection highlight
  static const Color caeruleus = Color(0xFF007BA7);
}

final Map<String, TextStyleDefinition> kDefaultTextStyles = const {
  'supertitle': TextStyleDefinition(size: RelativeFontSize(7 / 6)),
  'title': TextStyleDefinition(size: RelativeFontSize(3 / 2)),
  'subtitle': TextStyleDefinition(),
  'leftRight': TextStyleDefinition(size: RelativeFontSize(0.9)),
  'annotation': TextStyleDefinition(size: RelativeFontSize(2 / 3)),
  'dropCap': TextStyleDefinition(size: RelativeFontSize(4)),
  'al': TextStyleDefinition(),
  'choralSign': TextStyleDefinition(size: StaffIntervalFontSize(1.5)),
  'lyric': TextStyleDefinition(size: RelativeFontSize(0.9)),
  'translation': TextStyleDefinition(size: RelativeFontSize(0.75)),
};

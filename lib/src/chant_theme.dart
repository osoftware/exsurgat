import 'dart:ui';

import 'package:exsurgat/src/core.dart';

import 'chant_context.dart';
import 'drawing.dart';
import 'gabc.dart';

/// Default style for all texts, overriden by [TextStyleDefinition] for specific
/// text classes.
class BaseTextStyle {
  /// Font list using CSS syntax.
  final String font;

  /// Fons size.
  final Scalar size;

  /// Additional CSS properties.
  final Map<String, dynamic> baseStyle;

  const BaseTextStyle({
    required this.font,
    required this.size,
    this.baseStyle = const {},
  });

  /// Serialized representation of this base text style.
  Map<String, String> toMap() => {
    'font': font,
    'size': '$size',
    ...baseStyle.map((key, value) => MapEntry(key, '$value')),
  };

  factory BaseTextStyle.fromMap(Map<String, dynamic> map) {
    final values = Map<String, dynamic>.from(map)
      ..remove('font')
      ..remove('size');
    return BaseTextStyle(
      font: map['font'] as String,
      size: Scalar.parse('${map['size']}'),
      baseStyle: values,
    );
  }
}

/// Base class for text-size resolution strategies.
sealed class FontSize {
  const FontSize();

  factory FontSize.relative(double factor) = RelativeFontSize;

  factory FontSize.staffInterval(double multiplier) = StaffIntervalFontSize;

  factory FontSize.absolute(Scalar size) = AbsoluteFontSize;

  /// Resolves the concrete font size.
  double resolve(double baseSize, ChantContext ctxt);

  /// Serialized representation, e.g. `{'relative-size': 1.5}`.
  Map<String, dynamic> toMap();

  factory FontSize.fromMap(Map<String, dynamic> map) {
    final relative = map['relative-size'];
    if (relative != null) {
      return FontSize.relative(double.parse('$relative'));
    }
    final staffIntervalSize = map['staff-interval-size'];
    if (staffIntervalSize != null) {
      return FontSize.staffInterval(double.parse('$staffIntervalSize'));
    }
    return FontSize.absolute(Scalar.parse('${map['size']}'));
  }
}

/// Font size as a factor of the base text style size.
class RelativeFontSize extends FontSize {
  final double factor;

  const RelativeFontSize(this.factor);

  @override
  double resolve(double baseSize, ChantContext ctxt) => baseSize * factor;

  @override
  Map<String, dynamic> toMap() => {'relative-size': factor};
}

/// Font size derived from the staff interval of the [ChantContext].
class StaffIntervalFontSize extends FontSize {
  final double multiplier;

  const StaffIntervalFontSize(this.multiplier);

  @override
  double resolve(double baseSize, ChantContext ctxt) =>
      ctxt.staffInterval * multiplier;

  @override
  Map<String, double> toMap() => {'staff-interval-size': multiplier};
}

/// Fixed font size, independent of context.
class AbsoluteFontSize extends FontSize {
  final Scalar size;

  const AbsoluteFontSize(this.size);

  @override
  double resolve(double baseSize, ChantContext ctxt) => size.deviceIndependent;

  @override
  Map<String, dynamic> toMap() => {'size': size};
}

/// Style for a text class.
class TextStyleDefinition {
  const TextStyleDefinition({this.font, this.size, this.color});

  /// Font list using CSS syntax. Overrides font defined in baseTextStyle.
  final String? font;

  /// Size resolution strategy. Falls back to the base text style size.
  final FontSize? size;

  /// Text color. Overrides [ChantTheme.textColor] but not [ChantTheme.rubricColor].
  final Color? color;

  /// Serialized representation of this text style.
  Map<String, String> toMap() {
    final map = <String, String>{};
    if (font != null) map['font'] = font!;
    size?.toMap().forEach((key, value) => map[key] = '$value');
    if (color != null) map['color'] = color!.toSvgString();
    return map;
  }

  static TextStyleDefinition fromMap(Map<String, dynamic> map) {
    final hasSizing =
        map.containsKey('relative-size') ||
        map.containsKey('staff-interval-size') ||
        map.containsKey('size');
    return TextStyleDefinition(
      font: map['font'] as String?,
      size: hasSizing ? FontSize.fromMap(map) : null,
      color: parseColor(map['color'] as String?),
    );
  }
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

    if (baseTextStyle.font != kDefaultTheme.baseTextStyle.font) {
      header['base-text-style.font'] = baseTextStyle.font;
    } else {
      header.remove('base-text-style.font');
    }
    header.put(
      'base-text-style.size',
      '${baseTextStyle.size}',
      '${kDefaultTheme.baseTextStyle.size}',
    );
    baseTextStyle.baseStyle.forEach((key, value) {
      final kDefaultValue = kDefaultTheme.baseTextStyle.baseStyle[key];
      header.put('base-text-style.$key', '$value', '$kDefaultValue');
    });

    final kDefaultStyles = kDefaultTheme.textStyles;
    textStyles.forEach((name, style) {
      if (style == kDefaultStyles[name]) {
        // Remove any previously serialized properties for this style.
        header.keys
            .where((key) => key.startsWith('text-style.$name.'))
            .toList()
            .forEach(header.remove);
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
        : BaseTextStyle(
            font: base['font'] as String? ?? kDefaultBaseTextStyle.font,
            size:
                Scalar.tryParse('${base['size']}') ??
                kDefaultBaseTextStyle.size,
            baseStyle: Map.from(base)
              ..remove('font')
              ..remove('size'),
          );

    final styles = <String, Map<String, dynamic>>{};
    values.forEach((key, value) {
      final match = RegExp(
        r'^text-style\.([a-zA-Z]+)\.([a-zA-Z]+)$',
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

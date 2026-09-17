import 'dart:ui';

import 'chant_context.dart';
import 'drawing.dart';
import 'gabc.dart';

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
      size: double.parse('${map['size']}'),
      baseStyle: values,
    );
  }
}

/// Base class for text-size resolution strategies. Replaces raw callbacks so
/// that text styles remain serializable.
sealed class FontSize {
  const FontSize();

  factory FontSize.relative(double factor) = RelativeFontSize;

  factory FontSize.staffInterval(double multiplier) = StaffIntervalFontSize;

  factory FontSize.absolute(double size) = AbsoluteFontSize;

  /// Resolves the concrete font size.
  double resolve(double baseSize, ChantContext ctxt);

  /// Serialized representation, e.g. `{'relativeSize': 1.5}`.
  Map<String, double> toMap();

  factory FontSize.fromMap(Map<String, dynamic> map) {
    final relative = map['relativeSize'];
    if (relative != null) {
      return FontSize.relative(double.parse('$relative'));
    }
    final staffIntervalSize = map['staffIntervalSize'];
    if (staffIntervalSize != null) {
      return FontSize.staffInterval(double.parse('$staffIntervalSize'));
    }
    return FontSize.absolute(double.parse('${map['size']}'));
  }
}

/// Font size as a factor of the base text style size.
class RelativeFontSize extends FontSize {
  final double factor;

  const RelativeFontSize(this.factor);

  @override
  double resolve(double baseSize, ChantContext ctxt) => baseSize * factor;

  @override
  Map<String, double> toMap() => {'relativeSize': factor};
}

/// Font size derived from the staff interval of the [ChantContext].
class StaffIntervalFontSize extends FontSize {
  final double multiplier;

  const StaffIntervalFontSize(this.multiplier);

  @override
  double resolve(double baseSize, ChantContext ctxt) =>
      ctxt.staffInterval * multiplier;

  @override
  Map<String, double> toMap() => {'staffIntervalSize': multiplier};
}

/// Fixed font size, independent of context.
class AbsoluteFontSize extends FontSize {
  final double size;

  const AbsoluteFontSize(this.size);

  @override
  double resolve(double baseSize, ChantContext ctxt) => size;

  @override
  Map<String, double> toMap() => {'size': size};
}

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
        map.containsKey('relativeSize') ||
        map.containsKey('staffIntervalSize') ||
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
    this.baseTextStyle = defaultBaseTextStyle,
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

  /// Serializes this theme into header values, compatible with [GabcHeader].
  ///
  /// Only values that differ from the default theme are included.
  Map<String, String> toHeaderValues() {
    final values = <String, String>{};

    void putIfDifferent(String key, String value, String defaultValue) {
      if (value != defaultValue) values[key] = value;
    }

    putIfDifferent(
      'textColor',
      textColor.toSvgString(),
      kDefaultTheme.textColor.toSvgString(),
    );
    putIfDifferent(
      'rubricColor',
      rubricColor.toSvgString(),
      kDefaultTheme.rubricColor.toSvgString(),
    );
    putIfDifferent(
      'neumeColor',
      neumeColor.toSvgString(),
      kDefaultTheme.neumeColor.toSvgString(),
    );
    putIfDifferent(
      'staffLineColor',
      staffLineColor.toSvgString(),
      kDefaultTheme.staffLineColor.toSvgString(),
    );
    putIfDifferent(
      'dividerLineColor',
      dividerLineColor.toSvgString(),
      kDefaultTheme.dividerLineColor.toSvgString(),
    );
    putIfDifferent(
      'selectionColor',
      selectionColor.toSvgString(),
      kDefaultTheme.selectionColor.toSvgString(),
    );
    putIfDifferent(
      'minLedgerSeparation',
      '$minLedgerSeparation',
      '${kDefaultTheme.minLedgerSeparation}',
    );
    putIfDifferent(
      'minSpaceAboveStaff',
      '$minSpaceAboveStaff',
      '${kDefaultTheme.minSpaceAboveStaff}',
    );
    putIfDifferent(
      'minSpaceBelowStaff',
      '$minSpaceBelowStaff',
      '${kDefaultTheme.minSpaceBelowStaff}',
    );
    putIfDifferent(
      'spaceBetweenSystems',
      '$spaceBetweenSystems',
      '${kDefaultTheme.spaceBetweenSystems}',
    );

    if (baseTextStyle.font != kDefaultTheme.baseTextStyle.font) {
      values['baseTextStyle.font'] = baseTextStyle.font;
    }
    putIfDifferent(
      'baseTextStyle.size',
      '${baseTextStyle.size}',
      '${kDefaultTheme.baseTextStyle.size}',
    );
    baseTextStyle.baseStyle.forEach((key, value) {
      final defaultValue = kDefaultTheme.baseTextStyle.baseStyle[key];
      if ('$value' != '$defaultValue') {
        values['baseTextStyle.$key'] = '$value';
      }
    });

    final defaultStyles = kDefaultTheme.textStyles;
    textStyles.forEach((name, style) {
      if (style == defaultStyles[name]) return;
      style.toMap().forEach(
        (property, value) => values['textStyle.$name.$property'] = value,
      );
    });

    return values;
  }

  factory ChantTheme.fromGabcHeader(GabcHeader header) =>
      fromHeaderValues(header.toMap());

  /// Deserializes a theme from header values produced by [toHeaderValues].
  static ChantTheme fromHeaderValues(Map<String, dynamic> values) {
    Color readColor(String key, Color fallback) =>
        parseColor(values[key]) ?? fallback;

    double readDouble(String key, double fallback) =>
        double.tryParse(values[key] ?? '') ?? fallback;

    final base = <String, dynamic>{};
    values.forEach((key, value) {
      if (key.startsWith('baseTextStyle.')) {
        base[key.substring('baseTextStyle.'.length)] = value;
      }
    });
    final baseTextStyle = base.isEmpty
        ? defaultBaseTextStyle
        : BaseTextStyle(
            font: base['font'] as String? ?? defaultBaseTextStyle.font,
            size:
                double.tryParse('${base['size']}') ?? defaultBaseTextStyle.size,
            baseStyle: Map.from(base)
              ..remove('font')
              ..remove('size'),
          );

    final styles = <String, Map<String, dynamic>>{};
    values.forEach((key, value) {
      final match = RegExp(
        r'^textStyle\.([a-zA-Z]+)\.([a-zA-Z]+)$',
      ).firstMatch(key);
      if (match == null) return;
      styles.putIfAbsent(match.group(1)!, () => {})[match.group(2)!] = value;
    });

    TextStyleDefinition style(String name) {
      final map = styles[name];
      return map == null
          ? defaultTextStyles[name] ?? const TextStyleDefinition()
          : TextStyleDefinition.fromMap(map);
    }

    return ChantTheme(
      baseTextStyle: baseTextStyle,
      textColor: readColor('textColor', ChantColors.nigric),
      rubricColor: readColor('rubricColor', ChantColors.rubric),
      neumeColor: readColor('neumeColor', ChantColors.nigric),
      staffLineColor: readColor('staffLineColor', ChantColors.rubric),
      dividerLineColor: readColor('dividerLineColor', ChantColors.nigric),
      selectionColor: readColor('selectionColor', ChantColors.caeruleus),
      minLedgerSeparation: readDouble(
        'minLedgerSeparation',
        kDefaultMinLedgerSeparation,
      ),
      minSpaceAboveStaff: readDouble(
        'minSpaceAboveStaff',
        kDefaultMinSpaceAboveStaff,
      ),
      minSpaceBelowStaff: readDouble(
        'minSpaceBelowStaff',
        kDefaultMinSpaceBelowStaff,
      ),
      spaceBetweenSystems: readDouble(
        'spaceBetweenSystems',
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

const defaultBaseTextStyle = BaseTextStyle(
  font: "'Palatino Linotype', 'Book Antiqua', Palatino, serif",
  size: 16,
);

class ChantColors {
  /// Standard color for texts to read.
  static const Color nigric = Color(0xFF000000);

  /// Standart color for texts to obey.
  static const Color rubric = Color(0xFFDD0000);

  /// Selection highlight
  static const Color caeruleus = Color(0xFF007BA7);
}

final Map<String, TextStyleDefinition> defaultTextStyles = {
  'supertitle': const TextStyleDefinition(size: RelativeFontSize(7 / 6)),
  'title': const TextStyleDefinition(size: RelativeFontSize(3 / 2)),
  'subtitle': const TextStyleDefinition(),
  'leftRight': const TextStyleDefinition(size: RelativeFontSize(0.9)),
  'annotation': const TextStyleDefinition(size: RelativeFontSize(2 / 3)),
  'dropCap': const TextStyleDefinition(size: RelativeFontSize(4)),
  'al': const TextStyleDefinition(),
  'choralSign': const TextStyleDefinition(size: StaffIntervalFontSize(1.5)),
  'lyric': const TextStyleDefinition(size: RelativeFontSize(0.9)),
  'translation': const TextStyleDefinition(size: RelativeFontSize(0.75)),
};

import 'dart:ui';

import 'package:exsurgat/exsurgat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updateHeader replaces all theme values and preserves other fields', () {
    final header = GabcHeader.fromSource(
      'title: Example;\ninitial-lines: 3;\n'
      'text-color: #123456;\ntext-color: #654321;\n'
      'base-text-style.font: Old;\nbase-text-style.font-weight: bold;\n'
      'text-style.dropCap.font: Old;\ntext-style.dropCap.color: #123456;\n'
      '%%\n',
    );
    final theme = ChantTheme(
      baseTextStyle: const BaseTextStyle(
        font: 'New',
        size: Scalar(19.12),
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        features: [FontFeature('smcp')],
      ),
      dropCap: const TextStyleDefinition(font: 'Other'),
      lyric: const TextStyleDefinition(),
    );
    theme.updateHeader(header);
    final restored = ChantTheme.fromGabcHeader(
      GabcHeader.fromSource('$header'),
    );
    expect(restored, theme);
    expect(header['title'], 'Example');
    expect(header['text-color'], isNull);
    expect(header['initial-lines'], isNull);
    expect(header['text-style.dropCap.color'], isNull);
    expect(header['base-text-style.font-weight'], '500');
    expect(header['base-text-style.size'], '19.12di');
    ChantTheme().updateHeader(header);
    expect(
      ChantTheme.fromGabcHeader(GabcHeader.fromSource('$header')),
      ChantTheme(),
    );
    expect(header['base-text-style.font-weight'], isNull);
  });

  test('small absolute sizes survive native scalar serialization', () {
    final theme = ChantTheme(
      baseTextStyle: const BaseTextStyle(
        font: 'Test',
        size: Scalar(0.01),
        fontWeight: FontWeight.normal,
        fontStyle: FontStyle.normal,
      ),
      lyric: const TextStyleDefinition(
        size: AbsoluteFontSize(Scalar(0.2, Unit.millimeters)),
      ),
    );
    final header = GabcHeader.fromSource('%%\n');
    theme.updateHeader(header);
    expect(ChantTheme.fromGabcHeader(GabcHeader.fromSource('$header')), theme);
  });

  test('null text properties inherit base style values', () {
    const features = [FontFeature('smcp')];
    final theme = ChantTheme(
      baseTextStyle: const BaseTextStyle(
        font: 'Base',
        size: Scalar(20),
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        features: features,
      ),
      title: const TextStyleDefinition(),
    );
    final textStyle = ChantContext(theme: theme).textStyles['title']!;

    expect(textStyle['font'], 'Base');
    expect(textStyle['size'], 20);
    expect(textStyle['font-weight'], FontWeight.w600);
    expect(textStyle['font-style'], FontStyle.italic);
    expect(textStyle['font-variant'], features);
  });

  test('header omits text values matching inherited base style', () {
    final theme = ChantTheme(
      baseTextStyle: const BaseTextStyle(
        font: "'Palatino Linotype', 'Book Antiqua', Palatino, serif",
        size: Scalar(16),
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.normal,
        features: [],
      ),
      lyric: const TextStyleDefinition(
        fontStyle: FontStyle.normal,
        features: [],
      ),
    );
    final header = GabcHeader.fromSource('%%\n');

    theme.updateHeader(header);

    expect(header['base-text-style.font-weight'], 'bold');
    expect(header['text-style.lyric.font-weight'], isNull);
    expect(header['text-style.lyric.font-style'], isNull);
    expect(header['text-style.lyric.font-variant'], isNull);

    final restored = ChantTheme.fromGabcHeader(
      GabcHeader.fromSource('$header'),
    );
    final effectiveStyle = ChantContext(theme: theme).textStyles['lyric']!;
    final restoredStyle = ChantContext(theme: restored).textStyles['lyric']!;
    expect(restoredStyle['font-weight'], effectiveStyle['font-weight']);
    expect(restoredStyle['font-style'], effectiveStyle['font-style']);
    expect(restoredStyle['font-variant'], effectiveStyle['font-variant']);
  });

  test('explicit inheritance and empty features survive header round-trip', () {
    final theme = ChantTheme(
      baseTextStyle: const BaseTextStyle(
        font: "'Palatino Linotype', 'Book Antiqua', Palatino, serif",
        size: Scalar(16),
        fontWeight: FontWeight.normal,
        fontStyle: FontStyle.normal,
        features: [FontFeature('smcp')],
      ),
      aboveLine: const TextStyleDefinition(),
      title: const TextStyleDefinition(),
      lyric: const TextStyleDefinition(features: []),
    );
    final header = GabcHeader.fromSource('%%\n');

    theme.updateHeader(header);

    expect(header['text-style.al.font-style'], 'inherit');
    expect(header['text-style.title.size'], 'inherit');
    expect(header['text-style.lyric.font-variant'], 'normal');
    expect(
      ChantTheme.fromGabcHeader(GabcHeader.fromSource('$header')),
      theme,
    );

    final textStyles = ChantContext(theme: theme).textStyles;
    expect(textStyles['al']!['font-style'], FontStyle.normal);
    expect(textStyles['title']!['size'], 16);
    expect(textStyles['lyric']!['font-variant'], isEmpty);
  });
}

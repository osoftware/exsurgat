import 'package:exsurgat/exsurgat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const body = '''
%%
(c3)Ky(gh)ri(gf)e(e.) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) e(gvFD)le(ghg)í(gfe)son(f.) (,)
''';

  ChantDocument layout(String source, {double width = 260}) {
    final ctxt = ChantContext(textMeasuringStrategy: .svg);
    final doc = ChantDocument.fromSource(source, ctxt);
    doc.score
      ..performLayout(ctxt)
      ..layoutChantLines(ctxt, width);
    return doc;
  }

  group('ChantTheme.initialLines', () {
    test('defaults to 1 and is clamped between 0 and 4', () {
      expect(ChantTheme().initialLines, 1);
      expect(ChantTheme(initialLines: -2).initialLines, 0);
      expect(ChantTheme(initialLines: 9).initialLines, 4);
    });

    test('serializes to gabc header, omitting the default', () {
      final doc = ChantDocument.fromSource('mode: 1\n$body');
      expect(doc.toString(), isNot(contains('initial-lines')));

      doc.theme = doc.theme.copyWith(initialLines: 3);
      expect(doc.toString(), contains('initial-lines: 3'));
      expect(ChantDocument.fromSource(doc.toString()).theme.initialLines, 3);
    });

    test('is read from header, with legacy initial-style fallback', () {
      expect(
        ChantDocument.fromSource('initial-lines: 2\n$body').theme.initialLines,
        2,
      );
      expect(
        ChantDocument.fromSource('initial-lines: 8\n$body').theme.initialLines,
        4,
      );
      expect(
        ChantDocument.fromSource('initial-style: 0\n$body').theme.initialLines,
        0,
      );
    });
  });

  group('multi-line drop cap layout', () {
    test('0 lines disables the drop cap', () {
      final doc = layout('initial-lines: 0\n$body');
      expect(doc.score.dropCap, isNull);
      expect(doc.score.lines.first.staffLeft, 0);
    });

    test('1 line pushes only the first line', () {
      final doc = layout('initial-lines: 1\n$body');
      final lines = doc.score.lines;
      expect(doc.score.dropCap, isNotNull);
      expect(lines.length, greaterThan(2));
      expect(lines[0].staffLeft, greaterThan(0));
      expect(lines[1].staffLeft, 0);
      expect(
        doc.score.dropCap!.bounds.y,
        closeTo(lines[0].lyricLineBaseline, 0.001),
      );
    });

    test('2 lines push two lines and align to the second baseline', () {
      final doc = layout('initial-lines: 2\n$body');
      final lines = doc.score.lines;
      expect(lines.length, greaterThan(2));
      expect(lines[0].staffLeft, greaterThan(0));
      expect(lines[1].staffLeft, lines[0].staffLeft);
      expect(lines[2].staffLeft, 0);
      expect(
        doc.score.dropCap!.bounds.y,
        closeTo(
          lines[1].bounds.y - lines[0].bounds.y + lines[1].lyricLineBaseline,
          0.001,
        ),
      );
    });

    test('lines do not overlap and bounds cover the drop cap', () {
      final doc = layout('initial-lines: 4\n$body');
      final score = doc.score;
      for (var i = 1; i < score.lines.length; i++) {
        final prev = score.lines[i - 1];
        final line = score.lines[i];
        expect(
          line.bounds.y - line.origin.y,
          greaterThanOrEqualTo(prev.bounds.bottom - prev.origin.y - 0.001),
        );
      }
      final dropCapBottom =
          score.lines.first.bounds.y +
          score.dropCap!.bounds.y -
          score.dropCap!.origin.y +
          score.dropCap!.bounds.height;
      expect(score.bounds.bottom, greaterThanOrEqualTo(dropCapBottom - 0.001));
    });

    test('extrapolates baseline when score has fewer lines', () {
      final short = '''
initial-lines: 4
%%
(c3)Ky(gh)ri(gf)e(e.)
''';
      final doc = layout(short, width: 600);
      final score = doc.score;
      expect(score.lines, hasLength(1));
      final line = score.lines.first;
      expect(
        score.dropCap!.bounds.y,
        greaterThan(line.lyricLineBaseline + line.bounds.height),
      );
      final dropCapBottom =
          line.bounds.y +
          score.dropCap!.bounds.y -
          score.dropCap!.origin.y +
          score.dropCap!.bounds.height;
      expect(score.bounds.bottom, greaterThanOrEqualTo(dropCapBottom - 0.001));
    });

    test(
      'annotation sits above the multi-line drop cap inside line bounds',
      () {
        // Gap between annotation bottom and the drop cap top at 1 line is the
        // reference spacing; taller drop caps must not get closer than that.
        double? referenceGap;
        for (final count in [1, 2, 3]) {
          final doc = layout('annotation: Ant\ninitial-lines: $count\n$body');
          final score = doc.score;
          final dc = score.dropCap!;
          final a = score.annotation!;
          final line = score.lines.first;
          final baseline = count == 1
              ? line.lyricLineBaseline
              : score.lines[count - 1].bounds.y -
                    line.bounds.y +
                    score.lines[count - 1].lyricLineBaseline;
          final annotationTop = a.bounds.y - a.origin.y;
          final annotationBottom = annotationTop + a.bounds.height;
          final mHeight = doc.ctxt.textMeasurer.measureMHeight(dc, doc.ctxt);
          final gap = baseline - mHeight - annotationBottom;
          referenceGap ??= gap;
          expect(gap, greaterThanOrEqualTo(referenceGap - 0.001));
          expect(
            annotationTop,
            greaterThanOrEqualTo(line.notationBounds.y - 0.001),
            reason: 'initial-lines: $count',
          );
        }
      },
    );

    test('standalone score reads initialLines from context theme', () {
      final ctxt = ChantContext(theme: ChantTheme(initialLines: 0));
      final score = ChantScore(
        ctxt: ctxt,
        words: Gabc.fromSource(ctxt, body),
        header: GabcHeader.fromSource(body),
      );
      expect(score.dropCap, isNull);
      final withCap = ChantContext(theme: ChantTheme(initialLines: 2));
      expect(
        ChantScore(
          ctxt: withCap,
          words: Gabc.fromSource(withCap, body),
          header: GabcHeader.fromSource(body),
        ).dropCap,
        isNotNull,
      );
    });

    test('changing theme initialLines recreates the drop cap', () {
      final doc = layout('initial-lines: 0\n$body');
      expect(doc.score.dropCap, isNull);
      doc.theme = doc.theme.copyWith(initialLines: 2);
      expect(doc.score.dropCap, isNotNull);
      doc.theme = doc.theme.copyWith(initialLines: 0);
      expect(doc.score.dropCap, isNull);
    });
  });
}

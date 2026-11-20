import 'package:exsurgat/exsurgat.dart';
import 'package:exsurgat/internals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('text-only bounds match lyrics regardless of vowel position', () {
    final document = ChantDocument.fromSource(
      '%%\n(c3)An(g) Ave() strata() in()',
    );
    final score = document.score;
    score.performLayout(document.ctxt);
    final elements = score.notations.whereType<TextOnly>().toList();
    expect(elements, hasLength(3));
    for (final laidOut in [false, true]) {
      if (laidOut) score.layoutChantLines(document.ctxt, 800);
      for (final element in elements) {
        final lyric = element.lyrics.single;
        expect(element.bounds.x, closeTo(lyric.getLeft(), 0.001));
        expect(element.bounds.right, closeTo(lyric.getRight(), 0.001));
      }
    }
  });

  test('text-only bounds follow lyrics with syllable connectors', () {
    final document = ChantDocument.fromSource('%%\n(c3)An(g) al()le()lu()ia()');
    final score = document.score;
    score.performLayout(document.ctxt);
    score.layoutChantLines(document.ctxt, 800);

    final elements = score.notations.whereType<TextOnly>().toList();
    expect(elements, hasLength(4));
    for (final element in elements) {
      final lyric = element.lyrics.single;
      expect(element.bounds.x, closeTo(lyric.getLeft(), 0.001));
      expect(element.bounds.right, closeTo(lyric.getRight(), 0.001));
    }
  });

  test('text-only bounds follow connectors across staff lines', () {
    final document = ChantDocument.fromSource(
      '%%\n(c3)An(g) al()le()lu()ia() al()le()lu()ia()',
    );
    document.ctxt.useExtraTextOnly = false;
    final score = document.score;
    score.performLayout(document.ctxt);
    score.layoutChantLines(document.ctxt, 100);
    expect(score.lines.length, greaterThan(1));

    for (final element in score.notations.whereType<TextOnly>()) {
      final lyric = element.lyrics.single;
      expect(element.bounds.x, closeTo(lyric.getLeft(), 0.001));
      expect(element.bounds.right, closeTo(lyric.getRight(), 0.001));
    }
  });

  test('text-only bounds follow wrapped lyrics', () {
    final document = ChantDocument.fromSource(
      '%%\n(c3)An(g) A long passage with many words and vowels()',
    );
    final score = document.score;
    score.performLayout(document.ctxt);
    final element = score.notations.whereType<TextOnly>().single;
    for (final width in [180.0, 800.0, 180.0]) {
      score.layoutChantLines(document.ctxt, width);
      final lyric = element.lyrics.single;
      expect(element.bounds.x, closeTo(lyric.getLeft(), 0.001));
      expect(element.bounds.right, closeTo(lyric.getRight(), 0.001));
    }
  });

  test('empty text-only elements keep a usable placeholder width', () {
    final document = ChantDocument.fromSource('%%\n(c3)()');
    final score = document.score;
    score.performLayout(document.ctxt);
    score.layoutChantLines(document.ctxt, 800);

    final element = score.notations.whereType<TextOnly>().single;
    expect(element.bounds.width, greaterThan(0));
  });

  test('text-only bounds encompass all lyric verses', () {
    final document = ChantDocument.fromSource('%%\n(c3)A(g) Ave()');
    final score = document.score;
    final element = score.notations.whereType<TextOnly>().single;
    element.lyrics.add(
      Lyric(document.ctxt, 'strata', LyricType.singleSyllable, element),
    );
    score.performLayout(document.ctxt);
    score.layoutChantLines(document.ctxt, 800);

    final left = element.lyrics
        .map((lyric) => lyric.getLeft())
        .reduce((a, b) => a < b ? a : b);
    final right = element.lyrics
        .map((lyric) => lyric.getRight())
        .reduce((a, b) => a > b ? a : b);
    expect(element.bounds.x, closeTo(left, 0.001));
    expect(element.bounds.right, closeTo(right, 0.001));
  });

  test('realigning text-only bounds does not move lyric or translation', () {
    final document = ChantDocument.fromSource('%%\n(c3)Ave[Hello]()');
    final score = document.score;
    score.performLayout(document.ctxt);
    final element = score.notations.whereType<TextOnly>().single;
    final lyric = element.lyrics.single;
    final translation = element.translationText.single;
    lyric.bounds = lyric.bounds.copyWith(x: lyric.bounds.x - 12);
    final lyricLeft = lyric.getLeft();
    final translationLeft = element.bounds.x + translation.bounds.x;

    element.alignBoundsWithLyrics();

    expect(lyric.getLeft(), closeTo(lyricLeft, 0.001));
    expect(
      element.bounds.x + translation.bounds.x,
      closeTo(translationLeft, 0.001),
    );
    expect(element.bounds.x, closeTo(lyricLeft, 0.001));
  });
}

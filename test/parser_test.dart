import 'dart:ui';

import 'package:exsurgat/internals.dart';
import 'package:exsurgat/src/chant_context.dart';
import 'package:exsurgat/src/chant_document.dart';
import 'package:exsurgat/src/chant_theme.dart';
import 'package:exsurgat/src/gabc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Parser', () {
    final ctxt = ChantContext();
    final gabcSource = '''
mode:5
%%
Ex(ab)ur(dcd)gat(fg.) de(ab)us(fg.)
''';
    final gabcSource2 = '''
mode:5
%%
Ex(aba)ur(dcd)gat(fg.) de(ab)us(fg.)
''';
    test('Keeps translation end after editing a later translation', () {
      const header = 'mode:5\n%%\n';
      final ast = Gabc.fromSource(
        ctxt,
        '${header}A[a](a) b(b) C[c](c) d(d) E[/](e)',
      );
      Gabc.updateAstFromSource(
        ctxt,
        ast,
        '${header}A[a](a) b(b) C[cc](c) d(d) E[/](e)',
      );
      final translations = ast
          .expand((word) => word.notations)
          .expand((notation) => notation.translationText)
          .toList();
      expect(translations[1].sourceGabc, 'cc');
      expect(translations[1].endNeume, isNotNull);
    });

    test('Translation inserted before [/] takes over its end', () {
      const header = 'mode:5\n%%\n';
      final ast = Gabc.fromSource(
        ctxt,
        '$header(c3) A[x](g) b(g) c(g) d[/](g)',
      );
      List<TranslationText> translations() => ast
          .expand((word) => word.notations)
          .expand((notation) => notation.translationText)
          .toList();
      expect(translations().first.endNeume, isNotNull);
      Gabc.updateAstFromSource(
        ctxt,
        ast,
        '$header(c3) A[x](g) b[y](g) c(g) d[/](g)',
      );
      expect(translations()[0].endNeume, isNull);
      expect(translations()[1].endNeume, isNotNull);
      Gabc.updateAstFromSource(
        ctxt,
        ast,
        '$header(c3) A[x](g) b[y](g) c(g) d[/](g)',
      );
      const current = '$header(c3) A[x](g) b[y](g) c(g) d[/](g)';
      expect(translations()[1].sourceIndex, current.indexOf('[y]') + 1);
      expect(translations()[2].sourceIndex, current.indexOf('[/]') + 1);
      Gabc.updateAstFromSource(
        ctxt,
        ast,
        '$header(c3) A[x](g) b[y](g) c[/](g) d(g)',
      );
      expect(translations()[1].endNeume, isNotNull);
      expect(
        translations()[1].endNeume,
        same(translations()[2].notation),
      );
    });

    test('Translation realigns when its end moves without relayout', () {
      const header = 'mode:5\n%%\n';
      TranslationText y(ChantDocument doc) => doc.score.words
          .expand((word) => word.notations)
          .expand((notation) => notation.translationText)
          .firstWhere((text) => text.sourceGabc == 'yyyy');
      final doc = ChantDocument.fromSource(
        '$header(c3) A(g) b[yyyy](g) c(g) d[/](g)',
      );
      doc.score.performLayout(doc.ctxt);
      doc.score.layoutChantLines(doc.ctxt, 400);
      final before = y(doc).bounds.x;
      doc.updateSource('$header(c3) A(g) b[yyyy](g) c[/](g) d(g)');
      doc.score.performLayout(doc.ctxt);
      doc.score.layoutChantLines(doc.ctxt, 400);
      final shorter = y(doc).bounds.x;
      doc.updateSource('$header(c3) A(g) b[yyyy](g) c(g) d[/](g)');
      doc.score.performLayout(doc.ctxt);
      doc.score.layoutChantLines(doc.ctxt, 400);
      expect(shorter, isNot(before));
      expect(y(doc).bounds.x, closeTo(before, 0.001));
    });

    test('Word splitter preserves whitespace', () {
      final words = Gabc.splitWords(
        'Ex(ab)ur(dcd)gat(fg.) \nde(ab)us(fg.)\n et(ab)',
      );
      expect(
        words,
        equals(['Ex(ab)ur(dcd)gat(fg.) \n', 'de(ab)us(fg.)\n ', 'et(ab)']),
      );
    });

    test('Sets sourceIndex properly', () {
      final ast = Gabc.fromSource(ctxt, gabcSource);

      expect(ast.first.sourceIndex, equals(10));
      expect(ast.first.syllables.first.sourceIndex, equals(10));

      final neume1 = ast.first.notations.first as Neume;
      expect(neume1.notes.first.sourceIndex, equals(13));

      final neume2 = ast.first.notations[1] as Neume;
      expect(neume2.notes.first.sourceIndex, equals(19));

      expect(ast[1].sourceIndex, equals(32));
    });

    test('Updates sourceIndex properly', () {
      var ast = Gabc.fromSource(ctxt, gabcSource);
      Gabc.updateAstFromSource(ctxt, ast, gabcSource2);

      expect(ast.first.sourceIndex, equals(10));
      expect(ast.first.syllables.first.sourceIndex, equals(10));

      final neume1 = ast.first.notations.first as Neume;
      expect(neume1.notes.first.sourceIndex, equals(13));

      final neume2 = ast.first.notations[1] as Neume;
      expect(neume2.notes.first.sourceIndex, equals(20));

      final neume3 = ast[1].notations.first as Neume;
      expect(neume3.notes.first.sourceIndex, equals(36));

      expect(ast[1].sourceIndex, equals(33));
    });

    test('Text marker source indices include their syllable offsets', () {
      const source = 'mode:5\n%%\n(c3)Ex[xx](e)súr[alt:aa](g)gat(h)';
      final words = Gabc.fromSource(ctxt, source);
      final translations = words
          .expand((word) => word.notations)
          .expand((notation) => notation.translationText)
          .toList();
      final aboveLine = words
          .expand((word) => word.notations)
          .expand((notation) => notation.alText)
          .single;

      expect(
        translations.map(
          (text) => source.substring(
            text.sourceIndex,
            text.sourceIndex + text.sourceGabc.length,
          ),
        ),
        ['xx'],
      );
      expect(
        source.substring(
          aboveLine.sourceIndex,
          aboveLine.sourceIndex + aboveLine.sourceGabc.length,
        ),
        'aa',
      );
    });

    test('Updates sourceIndex for note-attached text', () {
      const source = 'mode:5\n%%\nA(c) B(d[cs:s][alt:t])';
      const updatedSource = 'mode:5\n%%\nA(cc) B(d[cs:s][alt:t])';
      final ast = Gabc.fromSource(ctxt, source);
      final note = (ast[1].notations.first as Neume).notes.first;
      final originalChoralSignIndex = note.choralSign!.sourceIndex;
      final originalAboveLineIndex = note.alText!.sourceIndex;

      Gabc.updateAstFromSource(ctxt, ast, updatedSource);

      final updatedNote = (ast[1].notations.first as Neume).notes.first;
      expect(updatedNote.choralSign!.sourceIndex, originalChoralSignIndex + 1);
      expect(updatedNote.alText!.sourceIndex, originalAboveLineIndex + 1);
    });

    test('Updates sourceIndex for syllables in unchanged later words', () {
      const source = 'mode:5\n%%\nA(c) B(d)';
      const updatedSource = 'mode:5\n%%\nA[alt:first](c) B(d)';
      final ast = Gabc.fromSource(ctxt, source);

      Gabc.updateAstFromSource(ctxt, ast, updatedSource);

      final laterSyllable = ast[1].syllables.first;
      expect(laterSyllable.sourceIndex, updatedSource.indexOf('B'));
      expect(
        updatedSource.substring(
          laterSyllable.sourceIndex,
          laterSyllable.sourceIndex + laterSyllable.rawLyrics.length,
        ),
        'B',
      );
    });

    test('Lays out note-attached above-line text', () {
      final document = ChantDocument.fromSource(
        'mode:5\n%%\nA[alt:rubric](c) B(m[alt:rubric])',
      );
      document.score.performLayout(document.ctxt);
      final aboveLines = document.score.notations
          .expand((notation) => notation.alText)
          .toList();
      final neume = document.score.notations.last as Neume;
      final aboveLine = neume.notes.first.alText!;

      expect(neume.alText, contains(aboveLine));
      expect(neume.visualizers, isNot(contains(aboveLine)));
      expect(aboveLine.bounds.width, greaterThan(0));
      expect(aboveLines, hasLength(2));
      expect(aboveLines[0].bounds.y, closeTo(aboveLines[1].bounds.y, 0.001));

      document.score.layoutChantLines(document.ctxt, 600);
      expect(aboveLines[0].bounds.y, closeTo(aboveLines[1].bounds.y, 0.001));
    });

    test('Keeps note-owned above-line text positioned over its note', () {
      final document = ChantDocument.fromSource(
        'mode:5\n%%\nA(c[alt:first]d[alt:second])',
      );
      document.score.performLayout(document.ctxt);
      document.score.layoutChantLines(document.ctxt, 600);
      final neume = document.score.notations.whereType<Neume>().firstWhere(
        (element) => element.notes.length == 2,
      );
      final firstText = neume.notes[0].alText!;
      final secondText = neume.notes[1].alText!;

      expect(neume.notes[1].bounds.x, greaterThan(neume.notes[0].bounds.x));
      expect(secondText.bounds.x, greaterThan(firstText.bounds.x));
    });
  });
  group('Document', () {
    final gabcSource = '''
mode: 5;
title: Exsurgat;
page-width: 21.0cm;
text-color: #111111ff;
%%
Ex(ab)ur(dcd)gat(fg.) de(ab)us(fg.)
Et(abc)
''';
    test('Loads layout and theme', () {
      final doc = ChantDocument.fromSource(gabcSource);
      expect(doc.layout.pageWidth, equals(Scalar(21, .centimeters)));
      expect(doc.theme.textColor, equals(Color(0xff111111)));
    });
    test('Preserves all props and content', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final saved = doc.toString();
      expect(saved, equals(gabcSource));
    });
    test('Serializes non-default values', () {
      final doc = ChantDocument.fromSource(gabcSource);
      doc.theme = ChantTheme(
        baseTextStyle: BaseTextStyle(
          font: 'Palatino',
          size: Scalar(16.0, .points),
        ),
        lyric: TextStyleDefinition(size: RelativeFontSize(1)),
      );
      final output = doc.toString();
      expect(output, contains('base-text-style.size: 16.0pt'));
      expect(output, contains('text-style.lyric.relative-size: 1.0'));
    });
  });
}

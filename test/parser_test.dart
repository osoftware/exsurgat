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

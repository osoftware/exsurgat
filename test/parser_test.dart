import 'package:exsurgat/internals.dart';
import 'package:exsurgat/src/chant_context.dart';
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
}

import 'package:exsurgat/src/chant_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChantDocument SVG font export', () {
    test('dropCap font from GABC header loads correctly', () {
      final gabc = '''text-style.dropCap.font: SolesmesCaps;
%%
(c3)Ex(e)súr(g)gat(h)
''';

      final doc = ChantDocument.fromSource(gabc);
      doc.score.performLayout(doc.ctxt);
      doc.score.layoutChantLines(doc.ctxt, 600);

      // Verify theme loaded correctly from GABC header
      final dropCapStyle = doc.ctxt.textStyles['dropCap'];
      expect(dropCapStyle, isNotNull, reason: 'dropCap style not found');
      expect(dropCapStyle!['font'], contains('SolesmesCaps'),
          reason: 'dropCap font should be SolesmesCaps');
    });

    test('regular lyric font loads correctly', () {
      final gabc = '''%%
(c3)Ex(e)súr(g)gat(h)
''';

      final doc = ChantDocument.fromSource(gabc);
      doc.score.performLayout(doc.ctxt);
      doc.score.layoutChantLines(doc.ctxt, 600);

      // Verify theme loaded correctly
      final lyricStyle = doc.ctxt.textStyles['lyric'];
      expect(lyricStyle, isNotNull, reason: 'lyric style not found');
      expect(lyricStyle!['font'], isNotNull,
          reason: 'lyric should have font defined');
    });
  });
}






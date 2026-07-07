import '../../../drawing.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class TorculusResupinus extends Neume {
  @override
  void positionMarkings() {
    positionPorrectusMarkings(notes[1], notes[2], notes[3]);
    positionClivisEpisemata(notes[1], notes[0]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final first = notes[0];
    final second = notes[1];
    final third = notes[2];
    final fourth = notes[3];

    GlyphCode firstGlyph;
    GlyphCode fourthGlyph;

    if (first.liquescent == LiquescentType.initioDebilis.value) {
      firstGlyph = GlyphCode.terminatingDesLiquescent;
    } else if (first.shape == NoteShape.quilisma) {
      firstGlyph = GlyphCode.quilisma;
    } else {
      firstGlyph = GlyphCode.punctumQuadratum;
    }

    if (hasFlag(fourth.liquescent, LiquescentType.small)) {
      fourthGlyph = GlyphCode.terminatingAscLiquescent;
    } else if (hasFlag(third.liquescent, LiquescentType.descending)) {
      fourthGlyph = GlyphCode.punctumQuadratumDesLiquescent;
    } else {
      fourthGlyph = GlyphCode.podatusUpper;
    }

    build(ctxt)
      ..noteAt(first, firstGlyph)
      ..withPorrectusSwash(start: second, end: third)
      ..noteAt(fourth, fourthGlyph);

    finishLayout(ctxt);
  }
}

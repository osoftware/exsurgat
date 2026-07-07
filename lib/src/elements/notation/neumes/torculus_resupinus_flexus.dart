import '../../../drawing.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class TorculusResupinusFlexus extends Neume {
  @override
  void positionMarkings() {
    positionPorrectusFlexusMarkings(notes[1], notes[2], notes[3], notes[4]);
    positionClivisEpisemata(notes[1], notes[0]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final first = notes[0];
    final second = notes[1];
    final third = notes[2];
    final fourth = notes[3];
    final fifth = notes[4];

    GlyphCode firstGlyph;
    var fourthGlyph = GlyphCode.punctumQuadratum;
    GlyphCode fifthGlyph;

    if (first.liquescent == LiquescentType.initioDebilis.value) {
      firstGlyph = GlyphCode.terminatingDesLiquescent;
    } else if (first.shape == NoteShape.quilisma) {
      firstGlyph = GlyphCode.quilisma;
    } else {
      firstGlyph = GlyphCode.punctumQuadratum;
    }

    if (hasFlag(fifth.liquescent, LiquescentType.small)) {
      fourthGlyph = GlyphCode.punctumQuadratumDesLiquescent;
      fifthGlyph = GlyphCode.terminatingDesLiquescent;
    } else if (hasFlag(fifth.liquescent, LiquescentType.ascending)) {
      fifthGlyph = GlyphCode.punctumQuadratumAscLiquescent;
    } else if (hasFlag(fifth.liquescent, LiquescentType.descending)) {
      fifthGlyph = GlyphCode.punctumQuadratumDesLiquescent;
    } else {
      fifthGlyph = GlyphCode.punctumQuadratum;
    }

    build(ctxt)
      ..noteAt(first, firstGlyph)
      ..withPorrectusSwash(start: second, end: third)
      ..noteAt(fourth, fourthGlyph)
      ..noteAt(fifth, fifthGlyph);

    finishLayout(ctxt);
  }
}

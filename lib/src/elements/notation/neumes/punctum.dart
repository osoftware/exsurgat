import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class Punctum extends Neume {
  @override
  void positionMarkings() {
    positionEpisemataAbove(notes[0]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final note = notes[0];
    GlyphCode glyph = GlyphCode.punctumQuadratum;

    if (note.liquescent != LiquescentType.none.value) {
      if (note.shape == NoteShape.inclinatum) {
        glyph = GlyphCode.punctumInclinatumLiquescent;
      } else if (note.shape == NoteShape.oriscus) {
        glyph = GlyphCode.oriscusLiquescent;
      } else if (hasFlag(note.liquescent, LiquescentType.ascending)) {
        glyph = GlyphCode.punctumQuadratumAscLiquescent;
      } else if (hasFlag(note.liquescent, LiquescentType.descending)) {
        glyph = GlyphCode.punctumQuadratumDesLiquescent;
      } else {
        glyph = GlyphCode.punctumQuadratumLiquescent;
      }
    } else {
      if (hasFlag(note.shapeModifiers, NoteShapeModifiers.cavum)) {
        glyph = GlyphCode.punctumCavum;
      } else if (note.shape == NoteShape.inclinatum) {
        glyph = GlyphCode.punctumInclinatum;
      } else if (note.shape == NoteShape.quilisma) {
        glyph = GlyphCode.quilisma;
      } else {
        glyph = GlyphCode.punctumQuadratum;
      }
    }

    build(ctxt).noteAt(note, glyph);

    finishLayout(ctxt);
  }
}

import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class Torculus extends Neume {
  @override
  void positionMarkings() {
    positionTorculusMarkings(notes[0], notes[1], notes[2]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final note1 = notes[0];
    final note2 = notes[1];
    final note3 = notes[2];

    GlyphCode glyph1;
    GlyphCode glyph3;

    if (note1.liquescent == LiquescentType.initioDebilis.value) {
      glyph1 = GlyphCode.terminatingDesLiquescent;
    } else if (note1.shape == NoteShape.quilisma) {
      glyph1 = GlyphCode.quilisma;
    } else {
      glyph1 = GlyphCode.punctumQuadratum;
    }

    if (hasFlag(note3.liquescent, LiquescentType.small)) {
      glyph3 = GlyphCode.terminatingDesLiquescent;
    } else if (hasFlag(note3.liquescent, LiquescentType.ascending)) {
      glyph3 = GlyphCode.punctumQuadratumAscLiquescent;
    } else if (hasFlag(note3.liquescent, LiquescentType.descending)) {
      glyph3 = GlyphCode.punctumQuadratumDesLiquescent;
    } else {
      glyph3 = GlyphCode.punctumQuadratum;
    }

    build(ctxt)
      ..noteAt(note1, glyph1)
      ..noteAt(note2, GlyphCode.punctumQuadratum)
      ..noteAt(note3, glyph3);

    finishLayout(ctxt);
  }
}

import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class ScandicusFlexus extends Neume {
  @override
  void positionMarkings() {
    if (notes[2].shape == NoteShape.virga) {
      positionPodatusMarkings(notes[0], notes[1]);
      positionClivisMarkings(notes[2], notes[3]);
    } else {
      positionEpisemataBelow(notes[0]);
      positionPodatusMarkings(notes[1], notes[2]);
      positionEpisemataAbove(notes[3]);
    }
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final first = notes[0];
    final second = notes[1];
    final third = notes[2];
    final fourth = notes[3];

    if (third.shape == NoteShape.virga) {
      build(ctxt)
        ..withPodatus(upper: first, lower: second)
        ..advanceBy(ctxt.intraNeumeSpacing)
        ..withClivis(upper: third, lower: fourth);
    } else {
      GlyphCode fourthGlyph = GlyphCode.punctumQuadratum;

      if (hasFlag(fourth.liquescent, LiquescentType.ascending)) {
        fourthGlyph = GlyphCode.punctumQuadratumAscLiquescent;
      } else if (hasFlag(fourth.liquescent, LiquescentType.descending)) {
        fourthGlyph = GlyphCode.punctumQuadratumDesLiquescent;
      }

      build(ctxt)
        ..noteAt(first, GlyphCode.punctumQuadratum)
        ..withPodatus(lower: second, upper: third)
        ..advanceBy(ctxt.intraNeumeSpacing)
        ..noteAt(fourth, fourthGlyph);
    }

    finishLayout(ctxt);
  }
}

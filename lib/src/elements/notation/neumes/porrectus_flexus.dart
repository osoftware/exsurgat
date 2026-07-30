import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class PorrectusFlexus extends Neume {
  @override
  void positionMarkings() {
    positionPorrectusFlexusMarkings(notes[0], notes[1], notes[2], notes[3]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final first = notes[0];
    final second = notes[1];
    final third = notes[2];
    final fourth = notes[3];

    var thirdGlyph = GlyphCode.punctumQuadratum;
    GlyphCode fourthGlyph;

    if (hasFlag(fourth.liquescent, LiquescentType.small)) {
      thirdGlyph = GlyphCode.punctumQuadratumDesLiquescent;
      fourthGlyph = GlyphCode.terminatingDesLiquescent;
    } else if (hasFlag(fourth.liquescent, LiquescentType.ascending)) {
      fourthGlyph = GlyphCode.punctumQuadratumAscLiquescent;
    } else if (hasFlag(fourth.liquescent, LiquescentType.descending)) {
      fourthGlyph = GlyphCode.punctumQuadratumDesLiquescent;
    } else {
      fourthGlyph = GlyphCode.punctumQuadratum;
    }

    build(ctxt)
      ..lineFrom(second)
      ..withPorrectusSwash(start: first, end: second)
      ..noteAt(third, thirdGlyph)
      ..noteAt(fourth, fourthGlyph);

    finishLayout(ctxt);
  }
}

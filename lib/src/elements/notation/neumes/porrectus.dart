import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class Porrectus extends Neume {
  @override
  void positionMarkings() {
    positionPorrectusMarkings(notes[0], notes[1], notes[2]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final first = notes[0];
    final second = notes[1];
    final third = notes[2];

    GlyphCode thirdGlyph;

    if (hasFlag(third.liquescent, LiquescentType.small)) {
      thirdGlyph = GlyphCode.terminatingAscLiquescent;
    } else if (hasFlag(third.liquescent, LiquescentType.descending)) {
      thirdGlyph = GlyphCode.punctumQuadratumDesLiquescent;
    } else {
      thirdGlyph = third.staffPosition - second.staffPosition > 1
          ? GlyphCode.podatusUpper
          : GlyphCode.podatusUpperShort;
    }

    build(ctxt)
      ..lineFrom(second)
      ..withPorrectusSwash(start: first, end: second)
      ..noteAt(third, thirdGlyph);

    finishLayout(ctxt);
  }
}

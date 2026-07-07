import '../../../drawing.dart';
import '../../../glyphs.dart';
import 'apostropha.dart';
import 'neume.dart';

class Tristropha extends Neume {
  @override
  void positionMarkings() {
    positionEpisemataAbove(notes[0]);
    positionEpisemataAbove(notes[1]);
    positionEpisemataAbove(notes[2]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);
    final glyphCodes = notes
        .map((note) => Apostropha.getNoteGlyphCode(note))
        .toList();
    final glyphAdvance = glyphCodes[0] == GlyphCode.stropha
        ? ctxt.intraNeumeSpacing / 2
        : ctxt.intraNeumeSpacing;

    build(ctxt)
      ..noteAt(notes[0], glyphCodes[0])
      ..advanceBy(glyphAdvance)
      ..noteAt(notes[1], glyphCodes[1])
      ..advanceBy(glyphAdvance)
      ..noteAt(notes[2], glyphCodes[2]);

    finishLayout(ctxt);
  }
}

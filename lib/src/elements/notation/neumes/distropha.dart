import '../../../chant_context.dart';
import '../../../glyphs.dart';
import 'apostropha.dart';
import 'neume.dart';

class Distropha extends Neume {
  @override
  void positionMarkings() {
    positionEpisemataAbove(notes[0]);
    positionEpisemataAbove(notes[1]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);
    final glyphCodes = notes
        .map((note) => Apostropha.getNoteGlyphCode(note))
        .toList();
    var glyphAdvance = ctxt.intraNeumeSpacing;
    for (var i = 0; i < 2 && i < glyphCodes.length; i++) {
      if (glyphCodes[i] == GlyphCode.stropha) {
        glyphAdvance -= ctxt.intraNeumeSpacing / 4;
      }
    }

    build(ctxt)
      ..noteAt(notes[0], glyphCodes[0])
      ..advanceBy(glyphAdvance)
      ..noteAt(notes[1], glyphCodes[1]);

    finishLayout(ctxt);
  }
}

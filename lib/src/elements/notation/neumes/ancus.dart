import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class Ancus extends Neume {
  @override
  void positionMarkings() {
    positionClivisMarkings(notes[0], notes[2]);
    positionClivisMarkings(notes[1], notes[2]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final upper = notes[0];
    final middle = notes[1];
    final lower = notes[2];

    final builder = build(ctxt);
    builder.withClivisUpper(upper: upper, lower: middle);
    var middleGlyph = GlyphCode.punctumQuadratum;
    if (hasFlag(lower.liquescent, LiquescentType.small)) {
      middleGlyph = GlyphCode.beginningDesLiquescent;
    }
    if (upper.staffPosition - middle.staffPosition > 1) {
      builder.withClivisUpper(upper: middle, lower: upper, glyph: middleGlyph);
    } else {
      builder.withClivisUpper(upper: middle, lower: null, glyph: middleGlyph);
    }
    builder.withClivisLower(lower);
    builder.lastNote = null;

    finishLayout(ctxt);
  }
}

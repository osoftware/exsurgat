import '../../../drawing.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class PesQuassus extends Neume {
  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final lower = notes[0];
    final upper = notes[1];

    GlyphCode lowerGlyph;

    final lowerStaffPos = lower.staffPosition;
    final upperStaffPos = upper.staffPosition;

    if (lower.shape == NoteShape.oriscus) {
      lowerGlyph = GlyphCode.oriscusAsc;
    } else {
      lowerGlyph = GlyphCode.punctumQuadratum;
    }

    final builder = build(ctxt).noteAt(lower, lowerGlyph);

    if (upperStaffPos - lowerStaffPos == 1) {
      builder.virgaAt(upper);
    } else if (hasAnyFlag(lower.liquescent,
        LiquescentType.large.value | LiquescentType.descending.value)) {
      builder
        ..noteAt(upper, GlyphCode.punctumQuadratumDesLiquescent)
        ..withLineEndingAt(lower);
    } else {
      builder
        ..noteAt(upper, GlyphCode.punctumQuadratum)
        ..withLineEndingAt(lower);
    }

    finishLayout(ctxt);
  }
}

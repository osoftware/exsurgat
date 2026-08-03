import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class SalicusFlexus extends Neume {
  @override
  void positionMarkings() {
    final hasTopEpisema = positionTorculusMarkings(
      notes[1],
      notes[2],
      notes[3],
    );
    positionEpisemata(
      notes[0],
      hasTopEpisema ? MarkingPositionHint.above : MarkingPositionHint.below,
    );
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final first = notes[0];
    final second = notes[1];
    final third = notes[2];
    final fourth = notes[3];

    final builder = build(ctxt)..noteAt(first, GlyphCode.punctumQuadratum);

    if (!(hasFlag(second.shapeModifiers, NoteShapeModifiers.stemmed))) {
      builder.advanceBy(ctxt.intraNeumeSpacing);
    }

    builder.noteAt(second, GlyphCode.oriscusAsc);

    if (hasFlag(fourth.liquescent, LiquescentType.small)) {
      builder.noteAt(third, GlyphCode.punctumQuadratumDesLiquescent);
    } else {
      builder.noteAt(third, GlyphCode.punctumQuadratum);
    }

    if (hasFlag(fourth.liquescent, LiquescentType.small)) {
      builder.noteAt(fourth, GlyphCode.terminatingDesLiquescent);
    } else if (hasFlag(fourth.liquescent, LiquescentType.ascending)) {
      builder.noteAt(fourth, GlyphCode.punctumQuadratumAscLiquescent);
    } else if (hasFlag(fourth.liquescent, LiquescentType.descending)) {
      builder.noteAt(fourth, GlyphCode.punctumQuadratumDesLiquescent);
    } else {
      builder.noteAt(fourth, GlyphCode.punctumQuadratum);
    }

    finishLayout(ctxt);
  }
}

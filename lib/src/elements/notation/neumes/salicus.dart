import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class Salicus extends Neume {
  @override
  void positionMarkings() {
    for (var i = 0; i < notes.length; i++) {
      positionEpisemataBelow(notes[i]);
    }
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final first = notes[0];
    final second = notes[1];
    final third = notes[2];

    final builder = build(ctxt).noteAt(first, GlyphCode.punctumQuadratum);

    if (!(hasFlag(second.shapeModifiers, NoteShapeModifiers.stemmed))) {
      builder.advanceBy(ctxt.intraNeumeSpacing);
    }

    builder.noteAt(second, GlyphCode.oriscusAsc);

    if (hasFlag(third.liquescent, LiquescentType.small)) {
      builder.noteAt(third, GlyphCode.terminatingAscLiquescent);
    } else if (third.liquescent == LiquescentType.ascending.value) {
      builder.noteAt(third, GlyphCode.punctumQuadratumAscLiquescent);
    } else if (third.liquescent == LiquescentType.descending.value) {
      builder.noteAt(third, GlyphCode.punctumQuadratumDesLiquescent);
    } else {
      builder.virgaAt(third);
    }

    finishLayout(ctxt);
  }
}

import '../../../drawing.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class Apostropha extends Neume {
  @override
  void positionMarkings() {
    var positionHint = MarkingPositionHint.above;

    for (var i = 0; i < notes[0].episemata.length; i++) {
      if (notes[0].episemata[i].positionHint ==
          MarkingPositionHint.defaultHint) {
        notes[0].episemata[i].positionHint = positionHint;
      } else {
        positionHint = notes[0].episemata[i].positionHint;
      }

      positionHint = positionHint == MarkingPositionHint.above
          ? MarkingPositionHint.below
          : MarkingPositionHint.above;
    }
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    build(ctxt).noteAt(notes[0], getNoteGlyphCode(notes[0]));

    finishLayout(ctxt);
  }

  static GlyphCode getNoteGlyphCode(Note note) {
    if (note.shape == NoteShape.stropha) return GlyphCode.stropha;

    if (hasFlag(note.liquescent, LiquescentType.ascending)) {
      return GlyphCode.punctumQuadratumAscLiquescent;
    } else if (hasFlag(note.liquescent, LiquescentType.descending)) {
      return GlyphCode.punctumQuadratumDesLiquescent;
    }

    if (hasFlag(note.shapeModifiers, NoteShapeModifiers.cavum)) {
      return GlyphCode.punctumCavum;
    }

    return GlyphCode.punctumQuadratum;
  }
}

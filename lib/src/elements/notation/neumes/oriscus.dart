import '../../../drawing.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class Oriscus extends Neume {
  @override
  void positionMarkings() {
    positionEpisemataAbove(notes.first);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final note = notes[0];
    GlyphCode glyph;

    if (note.liquescent != LiquescentType.none.value) {
      glyph = GlyphCode.oriscusLiquescent;
    } else {
      if (hasFlag(note.shapeModifiers, NoteShapeModifiers.ascending)) {
        glyph = GlyphCode.oriscusAsc;
      } else if (hasFlag(note.shapeModifiers, NoteShapeModifiers.descending)) {
        glyph = GlyphCode.oriscusDes;
      } else {
        glyph = GlyphCode.oriscusDes;

        final neume = ctxt.findNextNeume();

        if (neume != null) {
          final nextNoteStaffPosition = ctxt.activeClef!.pitchToStaffPosition(
            neume.notes.first.pitch!,
          );

          if (nextNoteStaffPosition > note.staffPosition) {
            glyph = GlyphCode.oriscusAsc;
          }
        }
      }
    }

    build(ctxt).noteAt(note, glyph);

    finishLayout(ctxt);
  }

  @override
  void resetDependencies() {
    if (hasAnyFlag(
      notes[0].shapeModifiers,
      NoteShapeModifiers.ascending.value | NoteShapeModifiers.descending.value,
    )) {
      return;
    }

    needsLayout = true;
  }
}

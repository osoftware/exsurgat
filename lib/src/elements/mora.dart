import '../drawing.dart';
import '../glyphs.dart';
import 'notation/neumes/note.dart';
import 'visualizers/glyph_visualizer.dart';

class Mora extends GlyphVisualizer {
  Note note;
  MarkingPositionHint positionHint = MarkingPositionHint.defaultHint;
  late double horizontalOffset;

  Mora(ChantContext ctxt, this.note) : super(ctxt, GlyphCode.mora) {
    horizontalOffset = ctxt.staffInterval / 2 + origin.x;
  }

  void performLayout(ChantContext ctxt) {
    setGlyph(ctxt, GlyphCode.mora);
    horizontalOffset = ctxt.staffInterval / 2 + origin.x;
    var staffPosition = note.staffPosition;

    setStaffPosition(ctxt, staffPosition);

    double verticalOffset = 0;
    // First, we need to find the next note in the neume.
    var noteIndex = note.neume!.notes.indexOf(note);
    Note? nextNote;
    if (noteIndex >= 0) {
      noteIndex++;
      if (note.neume!.notes.length > noteIndex) {
        nextNote = note.neume!.notes[noteIndex];
        if (nextNote.morae.isNotEmpty &&
            note.neume!.notes.length == noteIndex + 1) {
          // this note is the second to last in its neume, and the last note also has a mora
          horizontalOffset += nextNote.bounds.right - note.bounds.right;
        } else if (nextNote.bounds.right > note.bounds.right) {
          // center the dot over the following note.
          horizontalOffset =
              (nextNote.bounds.right - note.bounds.right - bounds.right) / 2;
        } else {
          nextNote = null;
        }
      } else if (note.neume!.notes.length == noteIndex) {
        // this note is the last in its neume:
        if (note.neume!.trailingSpace == 0) {
          // if this was the last note in its neume, we only care about the next note if there is no trailing space at the end of this neume.
          var notationIndex = note.neume!.score.notations.indexOf(note.neume);
          if (notationIndex >= 0) {
            var nextNotation = note.neume!.score.notations[notationIndex + 1];
            if (nextNotation != null && nextNotation.notes != null) {
              nextNote = nextNotation.notes![0];
            }
          }
        } else if (note.shape != NoteShape.inclinatum) {
          note.neume!.calculatedTrailingSpace += origin.x;
        }
      }
    }

    if (positionHint == MarkingPositionHint.above) {
      if (staffPosition % 2 == 0) {
        verticalOffset -= ctxt.staffInterval * 1.75;
      } else {
        verticalOffset -= ctxt.staffInterval * 0.75;
      }
    } else if (positionHint == MarkingPositionHint.below) {
      if (staffPosition % 2 == 0) {
        verticalOffset += ctxt.staffInterval * 1.75;
      } else {
        verticalOffset += ctxt.staffInterval * 0.75;
      }
    } else {
      if (staffPosition % 2 == 0) {
        // if the note is in a space and followed by a note on the line below, we often want to move the mora dot up slightly so that it is centered
        // between the top of the note's space and the top of the following note.
        if (nextNote != null && nextNote.staffPosition == staffPosition - 1) {
          verticalOffset -= ctxt.staffInterval * 0.25;
        }
      } else {
        verticalOffset -= ctxt.staffInterval * 0.75;
      }
    }

    bounds = bounds.copyWith(
      x: horizontalOffset + note.bounds.right,
      y: bounds.y + verticalOffset,
    );
  }
}

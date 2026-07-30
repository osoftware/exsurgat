import '../../chant_context.dart';
import '../../glyphs.dart';
import '../notation/neumes/note.dart';
import 'glyph_visualizer.dart';

class Ictus extends GlyphVisualizer {
  final Note note;
  MarkingPositionHint positionHint = MarkingPositionHint.defaultHint;

  Ictus(ChantContext ctxt, this.note)
    : super(ctxt, GlyphCode.verticalEpisemaAbove);

  void performLayout(ChantContext ctxt) {
    var glyphCode = note.glyphVisualizer!.glyphCode;
    // we have to place the ictus further from the note in some cases to avoid a collision with an episema on the same note:
    var currentPositionHint = positionHint != MarkingPositionHint.defaultHint
        ? positionHint
        : MarkingPositionHint.below;

    var staffPosition =
        note.staffPosition +
        (currentPositionHint == MarkingPositionHint.above ? 1 : -1);

    var collisionWithEpisema =
        note.episemata.isNotEmpty &&
        (note.episemata[0].positionHint != MarkingPositionHint.defaultHint
                ? note.episemata[0].positionHint
                : MarkingPositionHint.above) ==
            currentPositionHint;

    double horizontalOffset;
    double verticalOffset = 1;
    double shortOffset = -0.2;
    double extraOffset = 0;

    var collisionWithStaffLine =
        (staffPosition % 2 != 0) &&
        ((ctxt.convertStaffPositionToSymmetric(staffPosition).abs() <
                ctxt.staffLineCount) ||
            (note.neume!.ledgerLines.isNotEmpty &&
                note.neume!.ledgerLines.first.staffPosition == staffPosition));

    // The porrectus requires special handling of the note width,
    // otherwise the width is just that of the note itself
    if (glyphCode == GlyphCode.porrectus1 ||
        glyphCode == GlyphCode.porrectus2 ||
        glyphCode == GlyphCode.porrectus3 ||
        glyphCode == GlyphCode.porrectus4) {
      horizontalOffset = ctxt.staffInterval / 2;
    } else if (glyphCode == GlyphCode.none) {
      horizontalOffset = -ctxt.staffInterval / 2;
    } else {
      horizontalOffset = note.bounds.width / 2;
      if (glyphCode == GlyphCode.punctumInclinatum &&
          !collisionWithStaffLine &&
          !collisionWithEpisema) {
        extraOffset = 0.3;
      }
    }

    if (positionHint == MarkingPositionHint.above) {
      glyphCode = GlyphCode.verticalEpisemaAbove;
      verticalOffset *= -1;
    } else {
      glyphCode = GlyphCode.verticalEpisemaBelow;
    }

    if (collisionWithEpisema) {
      extraOffset = 0.4;
    }

    verticalOffset *=
        ctxt.staffInterval *
        (extraOffset + (collisionWithStaffLine ? 0.3 : shortOffset));

    setGlyph(ctxt, glyphCode);
    setStaffPosition(ctxt, staffPosition);

    bounds = bounds.copyWith(
      x: note.bounds.x + horizontalOffset - origin.x,
      y: bounds.y + verticalOffset,
    );
  }
}

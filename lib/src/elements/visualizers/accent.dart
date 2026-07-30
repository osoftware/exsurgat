import 'dart:math';

import '../../chant_context.dart';
import '../../glyphs.dart';
import '../notation/neumes/note.dart';
import 'glyph_visualizer.dart';

class Accent extends GlyphVisualizer {
  final Note note;
  final MarkingPositionHint positionHint = MarkingPositionHint.above;

  Accent(
    ChantContext ctxt,
    this.note, {
    GlyphCode glyphCode = GlyphCode.acuteAccent,
  }) : super(ctxt, glyphCode);

  void performLayout(ChantContext ctxt) {
    bounds = bounds.copyWith(
      x: note.bounds.x + bounds.width / 2,
    ); // center on the note itself

    // this puts the acute accent either over the staff lines, or over the note if the
    // note is above the staff lines
    setStaffPosition(
      ctxt,
      max(note.staffPosition + 1, 2 * ctxt.staffLineCount),
    );
  }
}

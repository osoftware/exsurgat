import '../../../drawing.dart';
import '../../../glyphs.dart';
import '../../visualizers/glyph_visualizer.dart';
import 'divider.dart';

class Virgula extends Divider {
  int staffPosition = 7;

  Virgula({super.hasCarryover = false}) {
    // unlike other dividers a virgula does not reset accidentals
    resetsAccidentals = false;
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final glyph = GlyphVisualizer(ctxt, GlyphCode.virgula);
    glyph.setStaffPosition(ctxt, staffPosition);

    addVisualizer(glyph);

    origin = Point(bounds.width / 2, origin.y);

    finishLayout(ctxt);
  }
}

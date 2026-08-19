import '../../core.dart';
import '../../glyphs.dart';
import '../visualizers/glyph_visualizer.dart';
import 'chant_notation_element.dart';

class TextOnly extends ChantNotationElement {
  TextOnly(int sourceIndex, int sourceLength) {
    this.sourceIndex = sourceIndex;
    this.sourceLength = sourceLength;
  }
  @override
  performLayout(ctxt) {
    super.performLayout(ctxt);

    // add an empty glyph as a placeholder
    addVisualizer(GlyphVisualizer(ctxt, GlyphCode.none, this));

    origin = Point(0, -ctxt.staffInterval);

    finishLayout(ctxt);
  }
}

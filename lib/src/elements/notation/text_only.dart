import 'dart:ui' as ui;

import '../../chant_context.dart';
import '../../core.dart';
import '../../drawing.dart';
import '../../glyphs.dart';
import '../visualizers/glyph_visualizer.dart';
import 'chant_notation_element.dart';

class TextOnly extends ChantNotationElement {
  TextOnly(int sourceIndex, int sourceLength) {
    this.sourceIndex = sourceIndex;
    this.sourceLength = sourceLength;
  }
  @override
  performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    // add an empty glyph as a placeholder
    addVisualizer(GlyphVisualizer(ctxt, GlyphCode.none, this));

    final width =
        lyrics.firstOrNull?.bounds.width ??
        ctxt.glyphPunctumWidth * ctxt.glyphScaling;
    final height = ctxt.staffInterval * ctxt.staffLineCount * 2;
    bounds = Rect.fromXYWH(0, -height, width, height);
    origin = Point(width / 2, -ctxt.staffInterval);

    finishLayout(ctxt);
  }

  @override
  void draw(ChantContext ctxt) {
    super.draw(ctxt);
    if (selected || highlight != null) {
      ctxt.canvas.beginPath(
          strokeWidth: 1,
          dashPattern: [4, 4],
          color: highlight ?? ctxt.theme.selectionColor,
        )
        ..rect(
          ui.Rect.fromLTWH(bounds.x, bounds.y, bounds.width, bounds.height),
        )
        ..stroke();
    }
  }
}

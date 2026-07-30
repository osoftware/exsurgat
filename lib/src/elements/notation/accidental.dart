import '../../chant_context.dart';
import '../../core.dart';
import '../../glyphs.dart';
import '../visualizers/glyph_visualizer.dart';
import 'chant_notation_element.dart';

enum AccidentalType {
  flat(-1),
  natural(0),
  sharp(1);

  final int value;

  const AccidentalType(this.value);
}

class Accidental extends ChantNotationElement {
  int staffPosition;
  AccidentalType accidentalType;
  Pitch? pitch;

  Accidental({required this.staffPosition, required this.accidentalType}) {
    keepWithNext = true;
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    addVisualizer(createGlyphVisualizer(ctxt));

    finishLayout(ctxt);
  }

  GlyphVisualizer createGlyphVisualizer(ChantContext ctxt) =>
      GlyphVisualizer(ctxt, switch (accidentalType) {
        AccidentalType.natural => GlyphCode.natural,
        AccidentalType.sharp => GlyphCode.sharp,
        AccidentalType.flat => GlyphCode.flat,
      })..setStaffPosition(ctxt, staffPosition);
}

import '../../../chant_context.dart';
import '../../../core.dart';
import '../accidental.dart';
import '../chant_notation_element.dart';
import 'do_clef.dart';

abstract class Clef extends ChantNotationElement {
  final int staffPosition;
  final int octave;
  final Accidental? defaultAccidental;
  Accidental? activeAccidental;

  Clef? model;

  Clef({
    required this.staffPosition,
    required this.octave,
    this.defaultAccidental,
  }) {
    keepWithNext = true;
    activeAccidental = defaultAccidental;
  }

  void resetAccidentals() {
    activeAccidental = defaultAccidental;
  }

  int pitchToStaffPosition(Pitch pitch);

  Pitch staffPositionToPitch(int staffPosition);

  @override
  void performLayout(ChantContext ctxt) {
    ctxt.activeClef = this;

    if (defaultAccidental != null) {
      defaultAccidental!.performLayout(ctxt);
    }

    super.performLayout(ctxt);
  }

  @override
  void finishLayout(ChantContext ctxt) {
    if (defaultAccidental != null) {
      var accidentalGlyph = defaultAccidental!.createGlyphVisualizer(ctxt);
      accidentalGlyph.bounds = accidentalGlyph.bounds.copyWith(
        x:
            accidentalGlyph.bounds.x +
            visualizers[0].bounds.right +
            ctxt.intraNeumeSpacing,
      );
      addVisualizer(accidentalGlyph);
    }

    super.finishLayout(ctxt);
  }

  static Clef defaultClef() {
    return defaultDoClef;
  }

  Clef clone();
}

final defaultDoClef = DoClef(staffPosition: 7, octave: 2);

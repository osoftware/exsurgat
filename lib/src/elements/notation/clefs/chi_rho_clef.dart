import '../../../drawing.dart';
import '../../../glyphs.dart';
import '../../visualizers/glyph_visualizer.dart';
import 'clef.dart';

class ChiRhoClef extends Clef {
  final bool sans;

  ChiRhoClef({
    required super.staffPosition,
    required super.octave,
    super.defaultAccidental,
    this.sans = false,
  }) {
    leadingSpace = 0;
  }

  @override
  int pitchToStaffPosition(Pitch pitch) {
    return (pitch.octave - octave) * 7 +
        staffPosition +
        Pitch.stepToStaffOffset(pitch.step) -
        Pitch.stepToStaffOffset(Step.ut);
  }

  @override
  Pitch staffPositionToPitch(int staffPosition) {
    var offset = staffPosition - this.staffPosition;
    var octaveOffset = (offset / 7).floor();

    var step = Pitch.staffOffsetToStep(offset).value;

    if (activeAccidental?.staffPosition == staffPosition) {
      step += activeAccidental!.accidentalType.value;
    }

    return Pitch(step, octave + octaveOffset);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    var glyph = GlyphVisualizer(
      ctxt,
      sans ? GlyphCode.chiRhoClefSans : GlyphCode.chiRhoClef,
    );
    glyph.setStaffPosition(ctxt, staffPosition);
    addVisualizer(glyph);

    finishLayout(ctxt);
  }

  @override
  ChiRhoClef clone() {
    if (model != null) return model!.clone() as ChiRhoClef;
    var clone = ChiRhoClef(
      staffPosition: staffPosition,
      octave: octave,
      defaultAccidental: defaultAccidental,
      sans: sans,
    );
    clone.leadingSpace = leadingSpace;
    clone.sourceGabc = sourceGabc;
    clone.sourceIndex = sourceIndex;
    clone.elementIndex = elementIndex;
    clone.model = this;
    return clone;
  }
}

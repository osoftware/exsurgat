import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import '../../visualizers/glyph_visualizer.dart';
import 'clef.dart';

class TrebleClef extends Clef {
  final bool small;

  TrebleClef({
    required super.staffPosition,
    required super.octave,
    super.defaultAccidental,
    this.small = false,
  }) {
    leadingSpace = 0;
  }

  @override
  int pitchToStaffPosition(Pitch pitch) {
    return (pitch.octave - octave) * 7 +
        staffPosition +
        Pitch.stepToStaffOffset(pitch.step) -
        Pitch.stepToStaffOffset(Step.so);
  }

  @override
  Pitch staffPositionToPitch(int staffPosition) {
    var offset = staffPosition - this.staffPosition + 4;
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
      small ? GlyphCode.trebleClefSmall : GlyphCode.trebleClef,
    );
    glyph.setStaffPosition(ctxt, staffPosition);
    addVisualizer(glyph);

    finishLayout(ctxt);
  }

  @override
  TrebleClef clone() {
    if (model != null) return model!.clone() as TrebleClef;
    var clone = TrebleClef(
      staffPosition: staffPosition,
      octave: octave,
      defaultAccidental: defaultAccidental,
      small: small,
    );
    clone.leadingSpace = leadingSpace;
    clone.sourceGabc = sourceGabc;
    clone.sourceIndex = sourceIndex;
    clone.elementIndex = elementIndex;
    clone.model = this;
    return clone;
  }
}

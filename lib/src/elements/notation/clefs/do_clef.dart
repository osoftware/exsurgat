import '../../../chant_context.dart';
import '../../../core.dart';
import '../../../glyphs.dart';
import '../../visualizers/glyph_visualizer.dart';
import 'clef.dart';

class DoClef extends Clef {
  DoClef({
    required super.staffPosition,
    required super.octave,
    super.defaultAccidental,
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

    if (activeAccidental != null &&
        activeAccidental!.staffPosition == staffPosition) {
      step += activeAccidental!.accidentalType.value;
    }

    return Pitch(step, octave + octaveOffset);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    addVisualizer(
      GlyphVisualizer(ctxt, GlyphCode.doClef, this)
        ..setStaffPosition(ctxt, staffPosition),
    );

    finishLayout(ctxt);
  }

  @override
  DoClef clone() {
    if (model != null) return model!.clone() as DoClef;
    var clone = DoClef(
      staffPosition: staffPosition,
      octave: octave,
      defaultAccidental: defaultAccidental,
    );
    clone.leadingSpace = leadingSpace;
    clone.sourceGabc = sourceGabc;
    clone.sourceIndex = sourceIndex;
    clone.elementIndex = elementIndex;
    clone.model = this;
    return clone;
  }
}

import 'package:exsurgat/src/elements/notation/accidental.dart';
import 'package:exsurgat/src/elements/notation/chant_notation_element.dart';
import 'package:exsurgat/src/core.dart';
import 'package:exsurgat/src/drawing.dart';
import 'package:exsurgat/src/elements/visualizer/glyph_visualizer.dart';
import 'package:exsurgat/src/glyphs.dart';

abstract class Clef extends ChantNotationElement {
  final int staffPosition;
  final int octave;
  final Accidental? defaultAccidental;
  Accidental? activeAccidental;
  bool isClef = true;

  String sourceGabc = '';
  int? sourceIndex;
  int? elementIndex;
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

  int pitchToStaffPosition(Pitch pitch) {
    return 0;
  }

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

    var glyph = GlyphVisualizer(ctxt, GlyphCode.doClef);
    glyph.setStaffPosition(ctxt, staffPosition);
    addVisualizer(glyph);

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

final defaultDoClef = DoClef(staffPosition: 7, octave: 2);

class FaClef extends Clef {
  FaClef({
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
        Pitch.stepToStaffOffset(Step.fa);
  }

  Pitch staffPositionToPitch(int staffPosition) {
    var offset = staffPosition - this.staffPosition + 3;
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

    var glyph = GlyphVisualizer(ctxt, GlyphCode.faClef);
    glyph.setStaffPosition(ctxt, staffPosition);
    addVisualizer(glyph);

    finishLayout(ctxt);
  }

  @override
  FaClef clone() {
    if (model != null) return model!.clone() as FaClef;
    var clone = FaClef(
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

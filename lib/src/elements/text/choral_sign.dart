import 'dart:math' as math;

import '../../chant_context.dart';
import '../notation/neumes/note.dart';
import 'text_element.dart';

class ChoralSign extends TextElement {
  ChoralSign(ChantContext ctxt, String text, this.note, int sourceIndex)
    : positionHint = MarkingPositionHint.defaultHint,
      super(
        ctxt,
        (ctxt.textStyles['choralSign']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['choralSign']?['font'],
        (ctxt) => ctxt.theme.choralSign.size!.call(ctxt),
        .start,
        sourceIndex,
        text,
      ) {
    textType = ctxt.theme.choralSign;
    spans.firstOrNull?.propertyArray.add({'line-height': 1.0});
  }

  MarkingPositionHint positionHint = MarkingPositionHint.defaultHint;
  Note note;

  void performLayout(ChantContext ctxt) {
    recalculateMetrics(ctxt);
    bounds = bounds.copyWith(
      x: note.bounds.x + math.max(0, (ctxt.staffInterval - bounds.width) / 2),
    );

    double staffPosition;
    if (positionHint == MarkingPositionHint.below) {
      staffPosition = note.staffPosition - 2;
      staffPosition += (staffPosition % 2 == 0) ? -0.7 : 0;
    } else {
      staffPosition = note.staffPosition + 1;
      staffPosition += (staffPosition % 2 == 1) ? 0.3 : -0.4;
    }
    bounds = bounds.copyWith(
      y:
          ctxt.calculateHeightFromStaffPosition(staffPosition) +
          origin.y -
          (ctxt.textMeasurer.align == .baseline ? 0 : bounds.height),
    );
  }
}

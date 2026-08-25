import 'dart:math' as math;

import '../../chant_context.dart';
import '../notation/neumes/note.dart';
import 'text_element.dart';

class ChoralSign extends TextElement {
  ChoralSign(ChantContext ctxt, String text, this.note, int sourceIndex)
    : positionHint = MarkingPositionHint.defaultHint,
      super(
        ctxt: ctxt,
        text: (ctxt.textStyles['choralSign']?['prefix'] ?? '') + text,
        cssClass: 'choralSign',
        fontFamily: (ctxt) => ctxt.textStyles['choralSign']?['font'],
        fontSize: (ctxt) => ctxt.textStyles['choralSign']?['size'],
        textAnchor: .start,
        sourceIndex: sourceIndex,
        sourceGabc: text,
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

  @override
  String toGabcString() => '[cs:${super.toGabcString()}]';
}

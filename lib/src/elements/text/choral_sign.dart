import '../../core.dart' as core;
import '../../drawing.dart';
import 'text_element.dart';

class ChoralSign extends TextElement {
  ChoralSign(ChantContext ctxt, String text, this.note, int sourceIndex)
    : positionHint = MarkingPositionHint.Default,
      super(
        ctxt,
        (ctxt.textStyles['choralSign']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['choralSign']?['font'],
        (ctxt) => ctxt.textStyles['choralSign']?['size'],
        'start',
        sourceIndex,
        text,
      ) {
    textType = TextTypes['choralSign']!;
  }

  MarkingPositionHint positionHint = MarkingPositionHint.Default;
  dynamic note;

  void performLayout(ChantContext ctxt) {
    recalculateMetrics(ctxt);
    bounds = core.Rect.fromXYWH(
      note.bounds.x +
          (ctxt.staffInterval - bounds.width).clamp(0.0, double.infinity),
      bounds.y,
      bounds.width,
      bounds.height,
    );

    double offset;
    double staffPosition;
    if (positionHint == MarkingPositionHint.Below) {
      offset = -1;
      staffPosition = note.staffPosition.toDouble() + 2 * offset;
      staffPosition += (staffPosition % 2 == 0) ? 0.3 : 1;
    } else {
      offset = 1;
      staffPosition = note.staffPosition.toDouble() + 2 * offset;
      staffPosition += (staffPosition % 2 == 0) ? 0.3 : -0.4;
    }

    bounds = core.Rect.fromXYWH(
      bounds.x,
      ctxt.calculateHeightFromStaffPosition(staffPosition.toInt()) + origin.y,
      bounds.width,
      bounds.height,
    );
  }
}

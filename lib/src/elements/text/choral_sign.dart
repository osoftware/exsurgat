import '../../chant_context.dart';
import '../../chant_theme.dart';
import '../../core.dart';
import '../notation/neumes/note.dart';
import 'text_element.dart';

class ChoralSign extends TextElement {
  ChoralSign(ChantContext ctxt, String text, this.note, int sourceIndex)
    : positionHint = MarkingPositionHint.defaultHint,
      super(
        ctxt,
        (ctxt.textStyles['choralSign']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['choralSign']?['font'],
        (ctxt) => ctxt.textStyles['choralSign']?['size'],
        'start',
        sourceIndex,
        text,
      ) {
    textType = defaultChantTheme['choralSign']!;
  }

  MarkingPositionHint positionHint = MarkingPositionHint.defaultHint;
  Note note;

  void performLayout(ChantContext ctxt) {
    recalculateMetrics(ctxt);
    bounds = Rect.fromXYWH(
      note.bounds.x +
          (ctxt.staffInterval - bounds.width).clamp(0.0, double.infinity),
      bounds.y,
      bounds.width,
      bounds.height,
    );

    double offset;
    double staffPosition;
    if (positionHint == MarkingPositionHint.below) {
      offset = -1;
      staffPosition = note.staffPosition.toDouble() + 2 * offset;
      staffPosition += (staffPosition % 2 == 0) ? 0.3 : 1;
    } else {
      offset = 1;
      staffPosition = note.staffPosition.toDouble() + 2 * offset;
      staffPosition += (staffPosition % 2 == 0) ? 0.3 : -0.4;
    }

    bounds = Rect.fromXYWH(
      bounds.x,
      ctxt.calculateHeightFromStaffPosition(staffPosition.toInt()) + origin.y,
      bounds.width,
      bounds.height,
    );
  }
}

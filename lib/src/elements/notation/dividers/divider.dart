import '../../../chant_context.dart';
import '../../../core.dart';
import '../../visualizers/round_brace_visualizer.dart';
import '../chant_notation_element.dart';

class Divider extends ChantNotationElement {
  bool hasCarryover;
  bool resetsAccidentals = true;

  Divider({this.hasCarryover = false});

  @override
  Rect get boundsForHitTest => super.boundsForHitTest.copyWith(
    x: super.boundsForHitTest.x - 2,
    width: super.boundsForHitTest.width + 4,
  );

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);
    if (hasCarryover) {
      final top = ctxt.staffLineCount * 2;
      final y = ctxt.calculateHeightFromStaffPosition(top);
      addVisualizer(
        RoundBraceVisualizer(
          ctxt,
          -ctxt.staffInterval * 1.5,
          ctxt.staffInterval * 1.5,
          y,
          true,
        ),
      );
    }
  }
}

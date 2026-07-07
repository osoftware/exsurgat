import '../../../drawing.dart';
import '../../visualizers/round_brace_visualizer.dart';
import '../chant_notation_element.dart';

class Divider extends ChantNotationElement {
  bool isDivider = true;
  bool hasCarryover;
  bool resetsAccidentals = true;

  Divider({this.hasCarryover = false});

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

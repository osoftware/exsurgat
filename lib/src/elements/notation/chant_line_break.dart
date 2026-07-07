import '../../core.dart';
import 'chant_notation_element.dart';

class ChantLineBreak extends ChantNotationElement {
  bool justify;

  ChantLineBreak(this.justify) {
    trailingSpace = 0;
    calculatedTrailingSpace = 0;
  }

  @override
  performLayout(ctxt) {
    // reset the bounds before doing a layout
    bounds = Rect.fromXYWH(0, 0, 0, 0);
  }

  ChantLineBreak clone() => ChantLineBreak(justify);
}

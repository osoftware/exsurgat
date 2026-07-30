import '../../../chant_context.dart';
import '../../../core.dart';
import '../../visualizers/divider_line_visualizer.dart';
import 'divider.dart';

class DominicanBar extends Divider {
  double staffPosition;

  DominicanBar(int staffPosition)
    : staffPosition = staffPosition - 2 * ((staffPosition + 1) % 2);

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);
    addVisualizer(
      DividerLineVisualizer(ctxt, staffPosition, staffPosition + 3, this),
    );

    origin = Point(bounds.width / 2, origin.y);

    finishLayout(ctxt);
  }
}

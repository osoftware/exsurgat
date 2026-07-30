import '../../../chant_context.dart';
import '../../../core.dart';
import '../../visualizers/divider_line_visualizer.dart';
import 'divider.dart';

class FullBar extends Divider {
  FullBar({super.hasCarryover = false});

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    addVisualizer(
      DividerLineVisualizer(ctxt, 1, ctxt.staffLineCount * 2 - 1, this),
    );

    origin = Point(bounds.width / 2, origin.y);

    finishLayout(ctxt);
  }
}

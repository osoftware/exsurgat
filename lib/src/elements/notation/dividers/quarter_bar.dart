import '../../../chant_context.dart';
import '../../../core.dart';
import '../../visualizers/divider_line_visualizer.dart';
import 'divider.dart';

class QuarterBar extends Divider {
  QuarterBar({super.hasCarryover = false});

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);
    final top = ctxt.staffLineCount * 2.0;
    addVisualizer(DividerLineVisualizer(ctxt, top - 2, top, this));
    origin = Point(bounds.width / 2, origin.y);

    finishLayout(ctxt);
  }
}

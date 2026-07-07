import '../../../drawing.dart';
import '../../visualizers/divider_line_visualizer.dart';
import 'divider.dart';

class HalfBar extends Divider {
  HalfBar({super.hasCarryover = false});

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final offset = ctxt.staffLineCount == 2 ? 1.5 : 2.0;
    addVisualizer(
      DividerLineVisualizer(
        ctxt,
        offset,
        ctxt.staffLineCount * 2 - offset,
        this,
      ),
    );

    origin = Point(bounds.width / 2, origin.y);

    finishLayout(ctxt);
  }
}

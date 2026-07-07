import '../../../drawing.dart';
import '../../visualizers/divider_line_visualizer.dart';
import 'divider.dart';

class DoubleBar extends Divider {
  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final top = ctxt.staffLineCount * 2.0 - 1;
    final line0 = DividerLineVisualizer(ctxt, 1, top, this);
    line0.bounds = line0.bounds.copyWith(width: 0);
    addVisualizer(line0);

    final line1 = DividerLineVisualizer(ctxt, 1, top, this);
    line1.bounds = line1.bounds.copyWith(
      x: ctxt.intraNeumeSpacing * 2 - line1.bounds.width,
    );
    addVisualizer(line1);

    origin = Point(bounds.width / 2, origin.y);

    finishLayout(ctxt);
  }
}

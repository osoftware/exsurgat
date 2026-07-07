import '../../../drawing.dart';
import '../../visualizers/divider_line_visualizer.dart';
import 'divider.dart';

class InsertionCursor extends Divider {
  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);
    cssClass = 'InsertionCursor';

    addVisualizer(DividerLineVisualizer(ctxt, 0, ctxt.staffLineCount * 2));

    origin = Point(bounds.width / 2, origin.y);
    bounds = bounds.copyWith(width: 0, height: 0);

    finishLayout(ctxt);
  }
}

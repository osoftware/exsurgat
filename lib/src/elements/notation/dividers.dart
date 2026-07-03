import '../../drawing.dart';
import '../../glyphs.dart';
import '../visualizer/divider_line_visualizer.dart';
import '../visualizer/glyph_visualizer.dart';
import '../visualizer/round_brace_visualizer.dart';
import 'chant_notation_element.dart';

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

class QuarterBar extends Divider {
  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);
    final top = ctxt.staffLineCount * 2.0;
    addVisualizer(DividerLineVisualizer(ctxt, top - 2, top, this));
    origin = Point(bounds.width / 2, origin.y);

    finishLayout(ctxt);
  }
}

class HalfBar extends Divider {
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

class FullBar extends Divider {
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

class Virgula extends Divider {
  int staffPosition = 7;

  Virgula({super.hasCarryover = false}) {
    // unlike other dividers a virgula does not reset accidentals
    resetsAccidentals = false;
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final glyph = GlyphVisualizer(ctxt, GlyphCode.virgula);
    glyph.setStaffPosition(ctxt, staffPosition);

    addVisualizer(glyph);

    origin = Point(bounds.width / 2, origin.y);

    finishLayout(ctxt);
  }
}

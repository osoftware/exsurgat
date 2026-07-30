import '../../chant_context.dart';
import '../../glyphs.dart';
import '../visualizers/glyph_visualizer.dart';
import 'brace_end.dart';
import 'chant_notation_element.dart';

class Custos extends ChantNotationElement with BraceEnd {
  bool auto;
  int staffPosition = 2;
  int? staffPositionOffset;

  Custos({this.auto = false});

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    if (auto) {
      final neume = ctxt.findNextNeume();

      if (neume != null) {
        final note = neume.notes[0];
        staffPosition =
            ctxt.activeClef!.pitchToStaffPosition(note.pitch!) +
            note.staffPositionOffset.toInt();
        staffPositionOffset = note.staffPositionOffset.toInt();
      }

      // in case there was a weird fa/do clef change, let's sanitize the staffPosition by making sure it is
      // within reasonable bounds
      while (staffPosition < -2) {
        staffPosition += 7;
      }

      while (staffPosition > 2 * ctxt.staffLineCount + 2) {
        staffPosition -= 7;
      }
    }

    addVisualizer(
      GlyphVisualizer(ctxt, getGlyphCode(staffPosition, ctxt.staffLineCount))
        ..setStaffPosition(ctxt, staffPosition),
    );

    finishLayout(ctxt);
  }

  void resetDependencies() {
    // we only need to resolve new dependencies if we're an automatic custos
    if (auto) {
      needsLayout = true;
    }
  }

  static GlyphCode getGlyphCode(int staffPosition, [int staffLineCount = 4]) {
    if (staffPosition <= staffLineCount * 2 - 2) {
      // ascending custos
      if (staffPosition.abs() % 2 == 1) {
        return GlyphCode.custosLong;
      } else {
        return GlyphCode.custosShort;
      }
    } else {
      // descending custos
      if (staffPosition.abs() % 2 == 1) {
        return GlyphCode.custosDescLong;
      } else {
        return GlyphCode.custosDescShort;
      }
    }
  }
}

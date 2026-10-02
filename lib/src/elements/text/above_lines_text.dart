import 'dart:math' as math;

import '../../chant_context.dart';
import '../chant_layout_element.dart';
import '../notation/neumes/note.dart';
import 'text_element.dart';

class AboveLinesText extends TextElement {
  AboveLinesText(ChantContext ctxt, String text, this.notation, int sourceIndex)
    : padding = ctxt.staffInterval / 2,
      super(
        ctxt: ctxt,
        text: (ctxt.textStyles['al']?['prefix'] ?? '') + text,
        cssClass: 'al',
        fontFamily: (ctxt) => ctxt.textStyles['al']?['font'],
        fontSize: (ctxt) => ctxt.textStyles['al']?['size'],
        textAnchor: .start,
        sourceIndex: sourceIndex,
        sourceGabc: text,
      ) {
    textType = ctxt.theme.aboveLine;
  }

  ChantLayoutElement notation;
  late double padding;

  void performLayout(ChantContext ctxt) {
    final owner = notation;
    if (owner is! Note) return;
    recalculateMetrics(ctxt);
    bounds = bounds.copyWith(
      x: owner.bounds.x + math.max(0, (ctxt.staffInterval - bounds.width) / 2),
    );
  }

  @override
  String toGabcString() => '[alt:${super.toGabcString()}]';
}

import '../../chant_context.dart';
import '../chant_layout_element.dart';
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

  @override
  String toGabcString() => '[alt:${super.toGabcString()}]';
}

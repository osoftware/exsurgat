import '../../chant_context.dart';
import 'title_text_element.dart';

class Supertitle extends TitleTextElement {
  Supertitle(ChantContext ctxt, String text, [int sourceIndex = 0])
    : super(
        ctxt: ctxt,
        text: (ctxt.textStyles['supertitle']?['prefix'] ?? '') + text,
        cssClass: 'supertitle',
        fontFamily: (ctxt) => ctxt.textStyles['supertitle']?['font'],
        fontSize: (ctxt) => ctxt.textStyles['supertitle']?['size'],
        textAnchor: .center,
        sourceIndex: sourceIndex,
        sourceGabc: text,
      ) {
    textType = ctxt.theme.supertitle;
    padding = (ctxt) =>
        ((ctxt.textStyles['supertitle']?['padding'] as num? ?? 1).toDouble() *
            (ctxt.textStyles['supertitle']?['size'] as num? ?? 16).toDouble()) /
        3;
  }

  late double Function(ChantContext ctxt) padding;
}

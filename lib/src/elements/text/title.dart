import '../../chant_context.dart';
import 'title_text_element.dart';

class Title extends TitleTextElement {
  Title(ChantContext ctxt, String text, [int sourceIndex = 0])
    : super(
        ctxt: ctxt,
        text: (ctxt.textStyles['title']?['prefix'] ?? '') + text,
        cssClass: 'title',
        fontFamily: (ctxt) => ctxt.textStyles['title']?['font'],
        fontSize: (ctxt) => ctxt.textStyles['title']?['size'],
        textAnchor: .center,
        sourceIndex: sourceIndex,
        sourceGabc: text,
      ) {
    textType = ctxt.theme.title;
    padding = (ctxt) =>
        ((ctxt.textStyles['title']?['padding'] as num? ?? 1).toDouble() *
            (ctxt.textStyles['title']?['size'] as num? ?? 16).toDouble()) /
        3;
  }

  late double Function(ChantContext ctxt) padding;
}

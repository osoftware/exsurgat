import '../../chant_context.dart';
import '../notation/chant_notation_element.dart';
import 'text_element.dart';

class TranslationText extends TextElement {
  TranslationText(
    ChantContext ctxt,
    String text,
    this.notation,
    int sourceIndex,
  ) : super(
        ctxt: ctxt,
        text: text == '/'
            ? ''
            : (ctxt.textStyles['translation']?['prefix'] ?? '') + text,
        cssClass: 'translation',
        fontFamily: (ctxt) => ctxt.textStyles['translation']?['font'],
        fontSize: (ctxt) => ctxt.textStyles['translation']?['size'],
        textAnchor: text == '/' ? .end : .start,
        sourceIndex: sourceIndex,
        sourceGabc: text,
      ) {
    textType = ctxt.theme.translation;
    padding = ctxt.staffInterval / 2;
  }

  final ChantNotationElement notation;
  late double padding;
  ChantNotationElement? endNeume;
}

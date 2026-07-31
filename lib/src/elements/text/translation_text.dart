import '../../chant_context.dart';
import '../../chant_theme.dart';
import '../notation/chant_notation_element.dart';
import 'text_element.dart';

class TranslationText extends TextElement {
  TranslationText(
    ChantContext ctxt,
    String text,
    this.notation,
    int sourceIndex,
  ) : super(
        ctxt,
        text == '/'
            ? ''
            : (ctxt.textStyles['translation']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['translation']?['font'],
        (ctxt) => ctxt.textStyles['translation']?['size'],
        text == '/' ? .end : .start,
        sourceIndex,
        text,
      ) {
    textType = defaultChantTheme['translation']!;
    padding = ctxt.staffInterval / 2;
  }

  final ChantNotationElement notation;
  late double padding;
  ChantNotationElement? endNeume;
}

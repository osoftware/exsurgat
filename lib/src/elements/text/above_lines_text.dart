import '../../chant_context.dart';
import '../../chant_theme.dart';
import '../chant_layout_element.dart';
import 'text_element.dart';

class AboveLinesText extends TextElement {
  AboveLinesText(ChantContext ctxt, String text, this.notation, int sourceIndex)
    : padding = ctxt.staffInterval / 2,
      super(
        ctxt,
        (ctxt.textStyles['al']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['al']?['font'],
        (ctxt) => ctxt.textStyles['al']?['size'],
        'start',
        sourceIndex,
        text,
      ) {
    textType = defaultChantTheme['al']!;
  }

  ChantLayoutElement notation;
  late double padding;
}

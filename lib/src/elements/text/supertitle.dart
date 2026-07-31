import '../../chant_context.dart';
import '../../chant_theme.dart';
import 'title_text_element.dart';

class Supertitle extends TitleTextElement {
  Supertitle(ChantContext ctxt, String text, [int sourceIndex = 0])
    : super(
        ctxt,
        (ctxt.textStyles['supertitle']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['supertitle']?['font'],
        (ctxt) => ctxt.textStyles['supertitle']?['size'],
        .center,
        sourceIndex,
        text,
      ) {
    textType = defaultChantTheme['supertitle']!;
    padding = (ctxt) =>
        ((ctxt.textStyles['supertitle']?['padding'] as num? ?? 1).toDouble() *
            (ctxt.textStyles['supertitle']?['size'] as num? ?? 16).toDouble()) /
        3;
  }

  late double Function(ChantContext ctxt) padding;
}

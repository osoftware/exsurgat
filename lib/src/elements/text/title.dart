import '../../chant_context.dart';
import '../../chant_theme.dart';
import 'title_text_element.dart';

class Title extends TitleTextElement {
  Title(ChantContext ctxt, String text, [int sourceIndex = 0])
    : super(
        ctxt,
        (ctxt.textStyles['title']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['title']?['font'],
        (ctxt) => ctxt.textStyles['title']?['size'],
        .center,
        sourceIndex,
        text,
      ) {
    textType = defaultChantTheme['title']!;
    padding = (ctxt) =>
        ((ctxt.textStyles['title']?['padding'] as num? ?? 1).toDouble() *
            (ctxt.textStyles['title']?['size'] as num? ?? 16).toDouble()) /
        3;
  }

  late double Function(ChantContext ctxt) padding;
}

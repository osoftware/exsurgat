import '../../chant_context.dart';
import '../../chant_theme.dart';
import 'title_text_element.dart';

class Subtitle extends TitleTextElement {
  Subtitle(ChantContext ctxt, String text, [int sourceIndex = 0])
    : super(
        ctxt,
        (ctxt.textStyles['subtitle']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['subtitle']?['font'],
        (ctxt) => ctxt.textStyles['subtitle']?['size'],
        'middle',
        sourceIndex,
        text,
      ) {
    textType = defaultChantTheme['subtitle']!;

    padding = (ctxt) =>
        ((ctxt.textStyles['subtitle']?['padding'] as num? ?? 1).toDouble() *
            (ctxt.textStyles['subtitle']?['size'] as num? ?? 16).toDouble()) /
        3;
  }

  late double Function(ChantContext ctxt) padding;
}

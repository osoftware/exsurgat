import '../../drawing.dart';
import 'text_element.dart';

class Annotation extends TextElement {
  Annotation(ChantContext ctxt, String text, this.elementIndex)
    : padding =
          ctxt.staffInterval *
          (ctxt.textStyles['annotation']?['padding'] as num? ?? 0).toDouble(),

      super(
        ctxt,
        (ctxt.textStyles['annotation']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['annotation']?['font'],
        (ctxt) => ctxt.textStyles['annotation']?['size'],
        'middle',
        0, // sourceIndex not provided in JS constructor
        text,
      ) {
    textType = TextTypes['annotation']!;
    dominantBaseline = 'hanging';
  }

  int? elementIndex;
  late double padding;
}

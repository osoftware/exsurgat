import '../../drawing.dart';
import 'text_element.dart';

class DropCap extends TextElement {
  DropCap(ChantContext ctxt, String text, int sourceIndex)
    : super(
        ctxt,
        (ctxt.textStyles['dropCap']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['dropCap']?['font'],
        (ctxt) => ctxt.textStyles['dropCap']?['size'],
        'middle',
        sourceIndex,
        text,
      ) {
    textType = TextTypes['dropCap']!;
    padding =
        ctxt.staffInterval * (ctxt.textStyles['dropCap']?['padding'] ?? 1);
  }

  late double padding;
}

import '../../chant_context.dart';
import '../../chant_theme.dart';
import 'title_text_element.dart';

class TextLeftRight extends TitleTextElement {
  TextLeftRight(
    ChantContext ctxt,
    String text,
    String type, [
    int sourceIndex = 0,
  ]) : extraClass = type == 'textLeft' ? 'textLeft' : 'textRight',
       headerKey = type == 'textLeft' ? 'text-left' : 'text-right',
       super(
         ctxt,
         (ctxt.textStyles['leftRight']?['prefix'] ?? '') + text,
         (ctxt) => ctxt.textStyles['leftRight']?['font'],
         (ctxt) => ctxt.textStyles['leftRight']?['size'],
         type == 'textLeft' ? .start : .end,
         sourceIndex,
         text,
       ) {
    textType = defaultChantTheme['leftRight']!;

    padding = (ctxt) =>
        ((ctxt.textStyles['leftRight']?['padding'] as num? ?? 1).toDouble() *
            (ctxt.textStyles['leftRight']?['size'] as num? ?? 16).toDouble()) /
        5;
  }

  String extraClass = '';
  String headerKey = '';
  late double Function(ChantContext ctxt) padding;

  @override
  String getCssClasses() {
    return '$extraClass ${super.getCssClasses()}';
  }
}

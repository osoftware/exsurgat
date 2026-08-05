import '../../chant_context.dart';
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
         ctxt: ctxt,
         text: (ctxt.textStyles['leftRight']?['prefix'] ?? '') + text,
         cssClass: 'leftRight',
         fontFamily: (ctxt) => ctxt.textStyles['leftRight']?['font'],
         fontSize: (ctxt) => ctxt.textStyles['leftRight']?['size'],
         textAnchor: type == 'textLeft' ? .start : .end,
         sourceIndex: sourceIndex,
         sourceGabc: text,
       ) {
    textType = ctxt.theme.leftRight;

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

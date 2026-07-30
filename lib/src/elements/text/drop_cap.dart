import '../../drawing.dart';
import 'lyric.dart';
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

  double baselineOffset(ChantContext ctxt) {
    if (ctxt.textMeasurer.align == .baseline) return 0;
    final dcProps = <String, dynamic>{
      ...getExtraStyleProperties(ctxt),
      'base-font-family': fontFamily(ctxt),
      'base-font-size': fontSize(ctxt),
    };
    final dc = spans.first.buildParagraph(ctxt, dcProps, .start);
    final lyric = Lyric(ctxt, 'M', .directive);
    final lProps = <String, dynamic>{
      ...lyric.getExtraStyleProperties(ctxt),
      'base-font-family': lyric.fontFamily(ctxt),
      'base-font-size': lyric.fontSize(ctxt),
    };
    final l = lyric.spans.first.buildParagraph(ctxt, lProps, .start);
    return l.alphabeticBaseline - dc.alphabeticBaseline;
  }
}

import 'dart:ui' as ui;

import '../../chant_context.dart';
import 'lyric.dart';
import 'text_element.dart';

class DropCap extends TextElement {
  DropCap(ChantContext ctxt, String text, int sourceIndex)
    : super(
        ctxt: ctxt,
        text: (ctxt.textStyles['dropCap']?['prefix'] ?? '') + text,
        cssClass: 'dropCap',
        fontFamily: (ctxt) => ctxt.textStyles['dropCap']?['font'],
        fontSize: (ctxt) => ctxt.textStyles['dropCap']?['size'],
        textAnchor: .center,
        sourceIndex: sourceIndex,
        sourceGabc: text,
      ) {
    textType = ctxt.theme.dropCap;
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
      'line-height': 1.0,
    };
    final dc = spans.first.buildParagraph(ctxt, dcProps, .start)
      ..layout(ui.ParagraphConstraints(width: double.infinity));
    final lyric = Lyric(ctxt, 'M', .directive);
    final lProps = <String, dynamic>{
      ...lyric.getExtraStyleProperties(ctxt),
      'base-font-family': lyric.fontFamily(ctxt),
      'base-font-size': lyric.fontSize(ctxt),
    };
    final l = lyric.spans.first.buildParagraph(ctxt, lProps, .start)
      ..layout(ui.ParagraphConstraints(width: double.infinity));
    return l.alphabeticBaseline - dc.alphabeticBaseline;
  }
}

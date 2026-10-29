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
    final dcStyle = ctxt.textStyles[cssClass]!;
    final dcProps = <String, dynamic>{
      ...getExtraStyleProperties(ctxt),
      'base-font-family': dcStyle['font'],
      'base-font-size': dcStyle['size'],
      'fill': ?dcStyle['fill'],
      'line-height': 1.0,
    };
    final dc = spans.first.buildParagraph(ctxt, dcProps, .start)
      ..layout(ui.ParagraphConstraints(width: double.infinity));
    final lyric = Lyric(ctxt, 'M', .directive);
    final lStyle = ctxt.textStyles['lyric']!;
    final lProps = <String, dynamic>{
      ...lyric.getExtraStyleProperties(ctxt),
      'base-font-family': lStyle['font'],
      'base-font-size': lStyle['size'],
    };
    final l = lyric.spans.first.buildParagraph(ctxt, lProps, .start)
      ..layout(ui.ParagraphConstraints(width: double.infinity));
    return l.alphabeticBaseline - dc.alphabeticBaseline;
  }
}

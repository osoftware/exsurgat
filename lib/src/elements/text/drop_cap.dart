import 'dart:ui' as ui;

import '../../chant_context.dart';
import '../../chant_theme.dart';
import 'lyric.dart';
import 'text_element.dart';

class DropCap extends TextElement {
  DropCap(ChantContext ctxt, String text, int sourceIndex)
    : super(
        ctxt,
        (ctxt.textStyles['dropCap']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['dropCap']?['font'],
        (ctxt) => ctxt.textStyles['dropCap']?['size'],
        .center,
        sourceIndex,
        text,
      ) {
    textType = defaultChantTheme['dropCap']!;
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

import '../../chant_context.dart';
import '../../chant_theme.dart';
import 'text_element.dart';

class Annotation extends TextElement {
  Annotation(ChantContext ctxt, String text, [this.elementIndex])
    : padding =
          ctxt.staffInterval *
          (ctxt.textStyles['annotation']?['padding'] as num? ?? 0).toDouble(),

      super(
        ctxt,
        (ctxt.textStyles['annotation']?['prefix'] ?? '') + text,
        (ctxt) => ctxt.textStyles['annotation']?['font'],
        (ctxt) => ctxt.textStyles['annotation']?['size'],
        .center,
        0, // sourceIndex not provided in JS constructor
        text,
      ) {
    textType = defaultChantTheme['annotation']!;
    dominantBaseline = 'hanging';
  }

  int? elementIndex;
  late double padding;

  /// The original, unmodified text of the annotation, before any prefix or
  /// markup processing. Mirrors the JavaScript `unsanitizedText` property
  /// used by `ChantScore.serializeToJson`.
  String get unsanitizedText => sourceGabc;
}

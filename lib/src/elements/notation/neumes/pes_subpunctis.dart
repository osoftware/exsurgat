import '../../../chant_context.dart';
import 'neume.dart';

class PesSubpunctis extends Neume {
  @override
  void positionMarkings() {
    positionPodatusEpisemata(notes[0], notes[1]);
    for (var i = 2; i < notes.length; i++) {
      positionEpisemataAbove(notes[i]);
    }
    positionInclinataMorae(notes.sublist(1));
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    build(ctxt)
      ..withPodatus(lower: notes[0], upper: notes[1])
      ..advanceBy(ctxt.intraNeumeSpacing * 0.68)
      ..withInclinata(notes.sublist(2));

    finishLayout(ctxt);
  }
}

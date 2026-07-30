import '../../../chant_context.dart';
import 'neume.dart';

class Climacus extends Neume {
  @override
  void positionMarkings() {
    for (var i = 0; i < notes.length; i++) {
      positionEpisemataAbove(notes[i]);
    }
    positionInclinataMorae(notes);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    build(ctxt)
      ..virgaAt(notes[0])
      ..advanceBy(ctxt.intraNeumeSpacing)
      ..withInclinata(notes.sublist(1));

    finishLayout(ctxt);
  }
}

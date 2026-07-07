import '../../../drawing.dart';
import 'neume.dart';

class Trivirga extends Neume {
  @override
  void positionMarkings() {
    positionEpisemataAbove(notes[0]);
    positionEpisemataAbove(notes[1]);
    positionEpisemataAbove(notes[2]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    build(ctxt)
      ..virgaAt(notes[0])
      ..advanceBy(ctxt.intraNeumeSpacing)
      ..virgaAt(notes[1])
      ..advanceBy(ctxt.intraNeumeSpacing)
      ..virgaAt(notes[2]);

    finishLayout(ctxt);
  }
}

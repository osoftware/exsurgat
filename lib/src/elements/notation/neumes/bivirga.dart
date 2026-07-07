import '../../../drawing.dart';
import 'neume.dart';

class Bivirga extends Neume {
  @override
  void positionMarkings() {
    positionEpisemataAbove(notes[0]);
    positionEpisemataAbove(notes[1]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    build(ctxt)
      ..virgaAt(notes[0])
      ..advanceBy(ctxt.intraNeumeSpacing)
      ..virgaAt(notes[1]);

    finishLayout(ctxt);
  }
}

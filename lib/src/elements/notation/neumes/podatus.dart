import '../../../chant_context.dart';
import 'neume.dart';

class Podatus extends Neume {
  @override
  void positionMarkings() {
    positionPodatusMarkings(notes[0], notes[1]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    build(ctxt).withPodatus(lower: notes[0], upper: notes[1]);

    finishLayout(ctxt);
  }
}

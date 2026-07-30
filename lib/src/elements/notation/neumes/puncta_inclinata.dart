import '../../../chant_context.dart';
import 'neume.dart';

class PunctaInclinata extends Neume {
  @override
  void positionMarkings() {
    positionInclinataMorae(notes);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    build(ctxt).withInclinata(notes);

    finishLayout(ctxt);
  }
}

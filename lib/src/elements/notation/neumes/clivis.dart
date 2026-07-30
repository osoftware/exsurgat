import '../../../chant_context.dart';
import 'neume.dart';

class Clivis extends Neume {
  @override
  void positionMarkings() {
    positionClivisMarkings(notes[0], notes[1]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final upper = notes[0];
    final lower = notes[1];

    build(ctxt).withClivis(upper: upper, lower: lower);

    finishLayout(ctxt);
  }
}

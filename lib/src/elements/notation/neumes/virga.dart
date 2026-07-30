import '../../../chant_context.dart';
import 'neume.dart';

class Virga extends Neume {
  @override
  void positionMarkings() {
    positionEpisemataAbove(notes[0]);
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    build(ctxt).virgaAt(notes[0]);

    finishLayout(ctxt);
  }
}

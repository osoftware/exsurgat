import '../../../chant_context.dart';
import '../../../glyphs.dart';
import 'neume.dart';
import 'note.dart';

class Scandicus extends Neume {
  @override
  void positionMarkings() {
    if (notes[2].shape == NoteShape.virga) {
      positionPodatusMarkings(notes[0], notes[1]);
      positionEpisemataAbove(notes[2]);
    } else {
      positionEpisemataBelow(notes[0]);
      positionPodatusMarkings(notes[1], notes[2]);
    }
  }

  @override
  void performLayout(ChantContext ctxt) {
    super.performLayout(ctxt);

    final first = notes[0];
    final second = notes[1];
    final third = notes[2];

    if (third.shape == NoteShape.virga) {
      build(ctxt).withPodatus(upper: first, lower: second).virgaAt(third);
    } else {
      build(ctxt)
        ..noteAt(
          first,
          first.shape == NoteShape.quilisma
              ? GlyphCode.quilisma
              : GlyphCode.punctumQuadratum,
        )
        ..withPodatus(lower: second, upper: third);
    }

    finishLayout(ctxt);
  }
}

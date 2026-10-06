import 'package:exsurgat/internals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pitch', () {
    test('normalizes negative absolute semitone values', () {
      expect(Pitch(-1).step, Step.ti);
      expect(Pitch(-1).octave, -1);
      expect(Pitch(-1).toInt(), -1);
      expect(Pitch(-12).step, Step.ut);
      expect(Pitch(-12).octave, -1);
      expect(Pitch(-12).toInt(), -12);
    });

    test('adjusts supplied octave for negative relative steps', () {
      final pitch = Pitch(-1, 4);

      expect(pitch.step, Step.ti);
      expect(pitch.octave, 3);
      expect(pitch.toInt(), 47);
    });

    test('adjusts supplied octave for steps outside one octave', () {
      expect(Pitch(12, 4).toInt(), 60);
      expect(Pitch(-13, 4).toInt(), 35);
    });
  });
}

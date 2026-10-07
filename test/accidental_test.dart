import 'package:exsurgat/internals.dart';
import 'package:exsurgat/src/chant_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accidental', () {
    test('toGabcString emits the bare atom for every kind', () {
      expect(
        Accidental(staffPosition: 4, accidentalType: .flat).toGabcString(),
        'gx',
      );
      expect(
        Accidental(staffPosition: 4, accidentalType: .sharp).toGabcString(),
        'g#',
      );
      expect(
        Accidental(staffPosition: 4, accidentalType: .natural).toGabcString(),
        'gy',
      );
    });

    test('toGabcString round-trips through the parser', () {
      final source = 'mode:5\n%%\nGloria(c3) (ex~) (gx) (fy)';
      final document = ChantDocument.fromSource(source);
      final accidentals = document.score.notes.whereType<Accidental>().toList();
      expect(accidentals.length, 3);
      for (final accidental in accidentals) {
        expect(accidental.toGabcString(), isNot(contains('(')));
        final reparsed = ChantDocument.fromSource(
          'mode:5\n%%\nGloria(c3) (${accidental.toGabcString()})',
        );
        final roundTripped = reparsed.score.notes.whereType<Accidental>().first;
        expect(roundTripped.staffPosition, accidental.staffPosition);
        expect(roundTripped.accidentalType, accidental.accidentalType);
      }
    });
  });
}

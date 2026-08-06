import 'package:exsurgat/src/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Syllabification', () {
    group('Polish', () {
      test('splits Polish text into syllables', () {
        final polish = Polish();
        final text = '''
          Bóg wstaje, a rozpraszają się Jego wrogowie
          i pierzchają przed Jego obliczem ci, którzy Go nienawidzą.
          Rozwiewają się, jak dym się rozwiewa,
          jak wosk się rozpływa przy ogniu,
          tak giną przed Bogiem grzesznicy.''';

        final syllabified = polish.syllabify(text);

        final expected = [
          ['Bóg'],
          ['wsta', 'je,'],
          ['a'],
          ['roz', 'pra', 'sza', 'ją'],
          ['się'],
          ['Je', 'go'],
          ['wro', 'go', 'wie'],
          ['i'],
          ['pie', 'rzcha', 'ją'],
          ['przed'],
          ['Je', 'go'],
          ['o', 'bli', 'czem'],
          ['ci,'],
          ['któ', 'rzy'],
          ['Go'],
          ['nie', 'na', 'wi', 'dzą.'],
          ['Roz', 'wie', 'wa', 'ją'],
          ['się,'],
          ['jak'],
          ['dym'],
          ['się'],
          ['roz', 'wie', 'wa,'],
          ['jak'],
          ['wosk'],
          ['się'],
          ['roz', 'pły', 'wa'],
          ['przy'],
          ['og', 'niu,'],
          ['tak'],
          ['gi', 'ną'],
          ['przed'],
          ['Bo', 'giem'],
          ['grzesz', 'ni', 'cy.'],
        ];

        expect(syllabified, expected);
      });
    });
  });
}

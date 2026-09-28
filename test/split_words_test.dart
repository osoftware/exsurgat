import 'package:exsurgat/exsurgat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splitWords keeps spaced lyrics in one word', () {
    expect(Gabc.splitWords('(c3) a b(d)'), ['(c3) ', 'a b(d)']);
    expect(Gabc.splitWords('(c3)  a b(d)'), ['(c3)  ', 'a b(d)']);
    expect(Gabc.splitWords('a(g) b(f)'), ['a(g) ', 'b(f)']);
    expect(Gabc.splitWords('head abc(no) de(fg)'), ['head abc(no) ', 'de(fg)']);
  });

  test('parseSource splits spaced-lyric words correctly', () {
    final words = Gabc.parseSource('(c3) a b(d)');
    expect(words.length, 2);
    expect(words[0][0].rawLyrics, '');
    expect(words[1][0].rawLyrics, 'a b');
    expect(words[1][0].sourceIndex, 5);
  });
}

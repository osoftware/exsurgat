import 'package:exsurgat/src/gabc.dart';

import 'elements/notation/chant_notation_element.dart';

/// A mapping between a source text fragment (e.g., a gabc word) and the
/// notations generated from it.
///
/// In the case of gabc, [source] is a text string that maps to a gabc word
/// (e.g.: "no(g)bis(fg)"). [notations] is an array of
/// [ChantNotationElement]s.
class Word {
  Word(this.source, this.syllables, this.notations, this.sourceIndex);

  /// The source text fragment that this mapping was generated from.
  String source;

  /// Syllables generated from [source].
  List<Syllable> syllables;

  /// The notations generated from [source].
  List<ChantNotationElement> notations;

  /// The index of [source] within the original gabc source string.
  int sourceIndex;
}

/// A simple data class used by [Gabc.parseWord].
class Syllable {
  Syllable({
    required this.rawNotations,
    required this.rawLyrics,
    required this.lyrics,
    required this.notations,
    required this.sourceIndex,
  });

  /// The raw gabc notations for this syllable.
  final String rawNotations;

  /// The raw lyrics for this syllable.
  final String rawLyrics;

  /// The lyrics split into lines.
  final List<String> lyrics;

  /// The notations generated from [rawNotations].
  final List<ChantNotationElement> notations;

  /// The index of [rawLyrics] within the original gabc source string.
  final int sourceIndex;
}

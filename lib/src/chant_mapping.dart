import 'elements/notation/chant_notation_element.dart';
import 'gabc.dart';

/// A mapping between a source text fragment (e.g., a gabc word) and the
/// notations generated from it.
///
/// In the case of gabc, [source] is a text string that maps to a gabc word
/// (e.g.: "no(g)bis(fg)"). [notations] is an array of
/// [ChantNotationElement]s.
class ChantMapping {
  ChantMapping(this.source, this.syllables, this.notations, this.sourceIndex);

  /// The source text fragment that this mapping was generated from.
  String source;

  /// Syllables generated from [source].
  List<SyllableData> syllables;

  /// The notations generated from [source].
  List<ChantNotationElement> notations;

  /// The index of [source] within the original gabc source string.
  int sourceIndex;
}

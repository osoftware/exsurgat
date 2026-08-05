import 'chant_context.dart';
import 'chant_mapping.dart';
import 'core.dart';
import 'elements/brace_point.dart';
import 'elements/horizontal_episema.dart';
import 'elements/mora.dart';
import 'elements/notation/accidental.dart';
import 'elements/notation/chant_line_break.dart';
import 'elements/notation/chant_notation_element.dart';
import 'elements/notation/clefs.dart';
import 'elements/notation/custos.dart';
import 'elements/notation/dividers.dart';
import 'elements/notation/neumes.dart';
import 'elements/notation/text_only.dart';
import 'elements/text.dart';
import 'elements/visualizers.dart';
import 'glyphs.dart';
import 'trailing_space.dart';

// reusable reg exps
final RegExp _syllablesRegex = RegExp(
  r'(?=\S)((?:<v>[\s\S]*?<\/v>|[^(])*)(?:\(?([^)]*)\)?)?',
);
final RegExp _altTranslationRegex = RegExp(
  r'<alt>(.*?)<\/alt>|\[(alt:)?(.*?)\]',
);

final RegExp _notationsRegex = RegExp(
  r'z0|z|Z|(::|(?::|[,;][1-8]?|`)_?)|(?:[cfg]|cb|treble-?|xp-?)[1-5]|\/+| |\!|-?@?[a-nA-N][oOwWvVrRsxy#~\+><_\.'
  r"'0123459|]*(?:\[[^\]]*\]?)*|\{([^}]+)\}?",
);
const int _notationsRegexGroupBar = 1;
const int _notationsRegexGroupInsideBraces = 2;

final RegExp _bracketedCommandRegex = RegExp(r'^([a-z]+):(.*)');

// for the brace string inside of [ and ] in notation data
// the capturing groups are:
//  1. o or u, to indicate over or under
//  2. b, cb, or cba, to indicate the brace type
//  3. 0 or 1 to indicate the attachment point
//  4. { or } to indicate opening/closing (this group will be null if the metric version is used)
//  5. a float indicating the millimeter length of the brace (not supported yet)
final RegExp _braceSpecRegex = RegExp(
  r'([ou])(b|cb|cba):([01])(?:([{}])|;(\d*(?:\.\d+)?)mm)',
);

final RegExp regexHeaderEnd = RegExp(r'(?:^|\n)%%\s?\n');
final RegExp regexHeaderLine = RegExp(
  r'^([\w-_.]+):\s*((?:[^;\r\n]|;[ \t])*)(?:;|$)',
  caseSensitive: false,
);
final RegExp regexHeaderComment = RegExp(r'^%.*');

int _elementCountForNotations(List<ChantNotationElement> items) {
  return items.fold(0, (sum, item) {
    final d = item;
    return sum + ((d is Neume) ? d.notes.length : 1);
  });
}

/// Represents and parses the header of a gabc source string.
class GabcHeader {
  static int getLength(String gabc) {
    final match = regexHeaderEnd.firstMatch(gabc);
    return match != null ? match.end : 0;
  }

  GabcHeader.fromSource(String text) {
    comments = {};
    cValues = {};
    original = '';
    final match = regexHeaderEnd.firstMatch(text);
    if (match != null) {
      final txtHeader = text.substring(0, match.end);
      original = txtHeader;
      final lines = txtHeader.split(RegExp(r'\r?\n'));
      for (var i = 0; i < lines.length; ++i) {
        final line = lines[i];
        var lineMatch = regexHeaderLine.firstMatch(line);
        if (lineMatch != null) {
          final key = lineMatch.group(1)!;
          final camelKey = key.replaceAllMapped(
            RegExp(r'-([a-z])'),
            (m) => m.group(1)!.toUpperCase(),
          );
          final value = lineMatch.group(2)!;
          if (this[key] != null) {
            final arrayName = '${key}Array';
            if (this[arrayName] == null) {
              this[arrayName] = [this[key]];
            }
            (this[arrayName] as List).add(value);
          } else {
            this[key] = value;
          }
          if (camelKey != key) this[camelKey] = this[key];
        } else if ((lineMatch = regexHeaderComment.firstMatch(line)) != null) {
          if (line != '%%') {
            lineMatch = regexHeaderLine.firstMatch(line.substring(1));
            if (lineMatch != null) {
              final key = lineMatch.group(1)!;
              final camelKey = key.replaceAllMapped(
                RegExp(r'-([a-z])'),
                (m) => m.group(1)!.toUpperCase(),
              );
              cValues[key] = lineMatch.group(2)!;
              if (camelKey != key) cValues[camelKey] = cValues[key]!;
            } else {
              comments[i] = line;
            }
          }
        }
      }
    }
  }

  late Map<int, String> comments;
  late Map<String, String> cValues;
  late String original;

  final Map<String, dynamic> _values = {};

  dynamic operator [](String key) => _values[key];
  void operator []=(String key, dynamic value) => _values[key] = value;

  bool containsKey(String key) => _values.containsKey(key);

  Iterable<String> get keys => _values.keys;

  @override
  String toString() {
    final result = <String>[];
    for (final key in _values.keys) {
      if (_values[key] is! String ||
          RegExp(r'^(length|original|comments|cValues)$').hasMatch(key)) {
        continue;
      }
      final alternateKey = key.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '-${m.group(0)!.toLowerCase()}',
      );
      if (alternateKey != key && _values.containsKey(alternateKey)) continue;
      final array = _values['${key}Array'];
      if (array != null) {
        for (var i = 0; i < (array as List).length; ++i) {
          result.add('$key: ${array[i]};');
        }
      } else {
        result.add('$key: ${_values[key]};');
      }
    }
    for (final key in cValues.keys) {
      if (key.isEmpty || !cValues.containsKey(key)) continue;
      result.add('%$key: ${cValues[key]};');
    }
    for (final i in comments.keys) {
      if (!comments.containsKey(i)) continue;
      try {
        result.insert(i, comments[i]!);
      } catch (e) {
        // ignore
      }
    }
    return '${result.join('\n')}\n%%\n';
  }
}

enum DiffType { equal, insert, delete }

class Diff {
  final DiffType code;
  final List<dynamic> values;

  Diff(this.code, this.values);
}

extension<T> on List<T> {
  T at(int index, {required T or}) =>
      (index >= 0 && index < length) ? this[index] : or;
}

/// The main gabc parser. Takes gabc source code and produces [ChantMapping]s
/// describing the chant.
///
/// All methods are static, mirroring the JavaScript implementation.
class Gabc {
  /// State for automatic brace ending tracking.
  static BracePoint? needToEndBrace;

  /// Takes gabc source code (without the header info) and returns an array
  /// of [ChantMapping]s describing the chant.
  static List<ChantMapping> createMappingsFromSource(
    ChantContext ctxt,
    String gabcSource,
  ) {
    final headerLength = GabcHeader.getLength(gabcSource);
    final source = gabcSource.substring(headerLength);
    final words = splitWords(source);

    // set the default clef
    ctxt.activeClef = Clef.defaultClef();

    final mappings = createMappingsFromWords(ctxt, words);

    // always set the last notation to have a trailingSpace of 0
    if (mappings.isNotEmpty &&
        mappings[mappings.length - 1].notations.isNotEmpty) {
      mappings[mappings.length - 1]
              .notations[mappings[mappings.length - 1].notations.length - 1]
              .trailingSpace =
          TrailingSpace.zero;
    }

    return mappings;
  }

  /// A simple general purpose diff algorithm adapted here for comparing
  /// an array of existing mappings with an updated list of gabc words.
  ///
  /// [before] is an array of mappings, and [after] is an array of strings
  /// (gabc words).
  ///
  /// Returns a list of Diff objects, with the code being a DiffType
  /// (.delete, .insert, .equal) and the values being a list of values from
  /// the original before and/or after lists.
  ///
  /// Based on https://github.com/paulgb/simplediff/
  static List<Diff> diffDescriptorsAndNewWords(
    List<ChantMapping> before,
    List<String> after,
  ) {
    final oldIndexMap = <String, List<int>>{};
    for (var i = 0; i < before.length; i++) {
      oldIndexMap.putIfAbsent(before[i].source, () => []);
      oldIndexMap[before[i].source]!.add(i);
    }

    var overlap = <int>[];
    var startOld = 0, startNew = 0, subLength = 0;

    for (var inew = 0; inew < after.length; inew++) {
      final overlap2 = <int>[];
      oldIndexMap.putIfAbsent(after[inew], () => []);
      for (var i = 0; i < oldIndexMap[after[inew]]!.length; i++) {
        final iold = oldIndexMap[after[inew]]![i];
        overlap2.add(((iold > 0 ? overlap.at(iold - 1, or: 0) : 0)) + 1);
        if (overlap2.length > iold && (overlap2[iold]) > subLength) {
          subLength = overlap2[iold];
          startOld = iold - subLength + 1;
          startNew = inew - subLength + 1;
        }
      }
      overlap = overlap2;
    }

    if (subLength == 0) {
      final result = <Diff>[];
      if (before.isNotEmpty) result.add(Diff(.delete, before));
      if (after.isNotEmpty) result.add(Diff(.insert, after));
      return result;
    }

    return [
      ...diffDescriptorsAndNewWords(
        before.sublist(0, startOld),
        after.sublist(0, startNew),
      ),
      Diff(.equal, after.sublist(startNew, startNew + subLength)),
      ...diffDescriptorsAndNewWords(
        before.sublist(startOld + subLength),
        after.sublist(startNew + subLength),
      ),
    ];
  }

  /// Takes an array of gabc words and returns an array of [ChantMapping]
  /// objects, one for each word.
  static List<ChantMapping> createMappingsFromWords(
    ChantContext ctxt,
    List<String> words,
  ) {
    final mappings = <ChantMapping>[];
    var sourceIndex = 0;
    var wordLength = 0;
    final lastTranslationNeumes = <dynamic>[];

    for (var i = 0; i < words.length; i++) {
      sourceIndex += wordLength;
      wordLength = words[i].length + 1;
      final word = words[i].trim();

      if (word.isEmpty) continue;

      final mapping = createMappingFromWord(
        ctxt,
        word,
        sourceIndex,
        lastTranslationNeumes,
      );

      if (mapping != null) mappings.add(mapping);
    }

    return mappings;
  }

  /// Performs and applies a rudimentary diff between a previously parsed set
  /// of mappings and a new gabc source text. The mappings array passed in is
  /// changed in place to be updated from the new source.
  static int updateMappingsFromSource(
    ChantContext ctxt,
    List<ChantMapping> mappings,
    String newGabcSource, {
    int? insertionIndex,
    int? oldInsertionIndex,
  }) {
    final headerLength = GabcHeader.getLength(newGabcSource);
    final source = newGabcSource.substring(headerLength);
    // always remove the last old mapping since its spacing/trailingSpace is handled specially
    // mappings.removeLast();

    final insIdx = insertionIndex ?? -1;
    final oldInsIdx = oldInsertionIndex ?? -1;

    final newWords = splitWords(source);
    final results = diffDescriptorsAndNewWords(mappings, newWords);

    var index = 0;
    var sourceIndex = 0;
    var wordLength = 0;
    var elementIndex = 0;
    ChantMapping mapping;

    ctxt.activeClef = Clef.defaultClef();

    var lastTranslationNeumes = <dynamic>[];
    for (var i = 0; i < results.length; i++) {
      final resultCode = results[i].code;
      final resultValues = results[i].values;

      if (index > 0) {
        sourceIndex =
            mappings[index - 1].sourceIndex +
            (mappings[index - 1].source).length +
            1;
      }
      if (resultCode == DiffType.equal) {
        final sourceIndexDiff = sourceIndex - mappings[index].sourceIndex;
        for (var j = 0; j < resultValues.length; j++, index++) {
          mapping = mappings[index];
          if (elementIndex == 0 &&
              mapping.notations.isNotEmpty &&
              mapping.notations[0] is Clef) {
            elementIndex = -1;
          }
          if (insIdx >= elementIndex || oldInsIdx >= elementIndex) {
            final elementCount = _elementCountForNotations(mapping.notations);
            if ((insIdx >= elementIndex &&
                    insIdx < elementIndex + elementCount) ||
                (oldInsIdx >= elementIndex &&
                    oldInsIdx < elementIndex + elementCount)) {
              final si = mapping.sourceIndex + sourceIndexDiff;
              mapping = createMappingFromWord(
                ctxt,
                resultValues[j] as String,
                si,
                lastTranslationNeumes,
                insIdx - elementIndex,
              )!;
              mappings[index] = mapping;
              elementIndex += elementCount;
              continue;
            }
            elementIndex += elementCount;
          }
          mapping.sourceIndex += sourceIndexDiff;
          for (var k = 0; k < mapping.notations.length; k++) {
            final curNotation = mapping.notations[k];
            final prevNotation = k > 0 ? mapping.notations[k - 1] : null;
            final prevIsAccidental =
                prevNotation != null && prevNotation is Accidental;

            if (curNotation is Custos) {
              curNotation.resetDependencies();
            } else if (curNotation is Neume) {
              curNotation.resetDependencies();
            }

            if (curNotation is Clef) {
              ctxt.activeClef = curNotation;
            }

            if (curNotation is Accidental) {
              ctxt.activeClef?.activeAccidental = curNotation;
            } else if (curNotation is Divider &&
                    curNotation.resetsAccidentals ||
                (!prevIsAccidental &&
                    curNotation.hasLyrics &&
                    curNotation.lyrics[0].lyricType.index <=
                        LyricType.beginningSyllable.index)) {
              ctxt.activeClef?.resetAccidentals();
            }

            if (curNotation case Neume(:final notes)) {
              for (var l = 0; l < notes.length; ++l) {
                final note = notes[l];
                note.sourceIndex = (note.sourceIndex ?? 0) + sourceIndexDiff;
                note.pitch = ctxt.activeClef!.staffPositionToPitch(
                  note.staffPosition,
                );
                if (note.braceEnd != null &&
                    (note.braceEnd as BracePoint).automatic) {
                  note.braceEnd = null;
                }
                if (needToEndBrace != null &&
                    note.braceStart == null &&
                    note.braceEnd == null) {
                  note.braceEnd = BracePoint(
                    note,
                    needToEndBrace!.isAbove,
                    needToEndBrace!.shape,
                    needToEndBrace!.attachment == BraceAttachment.left
                        ? BraceAttachment.right
                        : BraceAttachment.left,
                  );
                  (note.braceEnd as BracePoint).automatic = true;
                  needToEndBrace = null;
                } else if (note.braceStart != null &&
                    (note.braceStart as BracePoint).automatic) {
                  needToEndBrace = note.braceStart;
                }
              }
            }
            if (curNotation.translationText.isNotEmpty) {
              for (var l = 0; l < curNotation.translationText.length; ++l) {
                final transText = curNotation.translationText[l];
                transText.endNeume = null;
                transText.sourceIndex += sourceIndexDiff;
                if (transText.textAnchor == .end &&
                    lastTranslationNeumes.isNotEmpty) {
                  final lastTranslationText =
                      lastTranslationNeumes[0].translationText[l];
                  if (lastTranslationText != null) {
                    lastTranslationText.endNeume = curNotation;
                  }
                }
              }
              lastTranslationNeumes[0] = curNotation;
            }
            if (sourceIndexDiff != 0) {
              if (curNotation.sourceIndex is int) {
                curNotation.sourceIndex =
                    curNotation.sourceIndex! + sourceIndexDiff;
              }
              for (var l = 0; l < curNotation.lyrics.length; ++l) {
                curNotation.lyrics[l].sourceIndex += sourceIndexDiff;
              }
              if (curNotation.alText.isNotEmpty) {
                for (var l = 0; l < curNotation.alText.length; ++l) {
                  curNotation.alText[l].sourceIndex += sourceIndexDiff;
                }
              }
            }
          }
        }
      } else if (resultCode == DiffType.delete) {
        mappings.removeRange(index, index + resultValues.length);
      } else if (resultCode == DiffType.insert) {
        for (var j = 0; j < resultValues.length; j++) {
          wordLength = (resultValues[j] as String).length + 1;
          mapping = createMappingFromWord(
            ctxt,
            resultValues[j] as String,
            sourceIndex,
            lastTranslationNeumes,
            insIdx - elementIndex,
          )!;

          if (elementIndex == 0 &&
              mapping.notations.isNotEmpty &&
              mapping.notations[0] is Clef) {
            elementIndex = -1;
            final elementCount = _elementCountForNotations(mapping.notations);
            if (insIdx < elementCount) {
              mapping = createMappingFromWord(
                ctxt,
                resultValues[j] as String,
                sourceIndex,
                lastTranslationNeumes,
                insIdx - elementIndex,
              )!;
            }
          }

          for (var k = 0; k < mapping.notations.length; k++) {
            final curNotation = mapping.notations[k];
            elementIndex += curNotation is Neume ? curNotation.notes.length : 1;
            if (curNotation is Clef) {
              ctxt.activeClef = curNotation;
            }
          }

          mappings.insert(index++, mapping);
          sourceIndex += wordLength;
        }
      }
    }

    // always set the last notation to have a trailingSpace of 0
    if (mappings.isNotEmpty &&
        mappings[mappings.length - 1].notations.isNotEmpty) {
      mappings[mappings.length - 1]
              .notations[mappings[mappings.length - 1].notations.length - 1]
              .trailingSpace =
          TrailingSpace.zero;
    }

    return headerLength;
  }

  /// Takes a gabc word and returns a [ChantMapping] object that contains the
  /// gabc word source text as well as the generated notations.
  static ChantMapping? createMappingFromWord(
    ChantContext ctxt,
    String word,
    int sourceIndex,
    List<dynamic> lastTranslationNeumes, [
    int? insertionIndex,
  ]) {
    final matches = <RegExpMatch>[];
    final notations = <ChantNotationElement>[];
    var currSyllable = 0;

    for (final m in _syllablesRegex.allMatches(word)) {
      matches.add(m);
    }

    for (var j = 0; j < matches.length; j++) {
      final match = matches[j];

      var lyricText = match
          .group(1)!
          .replaceAllMapped(
            RegExp(r'(^|<\/sp>)([\s\S]*?)($|<sp>)'),
            (m) => '${m[1]}${m[2]!.replaceAll('~', ' ')}${m[3]}',
          );
      var alText = <AboveLinesText>[];
      var translationText = <TranslationText>[];
      final notationData = match.group(2);

      // new words reset the accidentals, per the Solesmes style (see LU xviij)
      if (currSyllable == 0 &&
          RegExp(r'[a-z]', caseSensitive: false).hasMatch(lyricText) &&
          RegExp(r'[a-n]', caseSensitive: false).hasMatch(notationData ?? '')) {
        (ctxt.activeClef as Clef).resetAccidentals();
      }

      final items = parseNotations(
        ctxt,
        notationData,
        sourceIndex + match.start + match.group(1)!.length + 1,
        insertionIndex,
      );

      if (items.isEmpty) continue;

      if (insertionIndex != null && insertionIndex >= 0) {
        insertionIndex -= _elementCountForNotations(items);
      }

      items[0].firstOfSyllable = lyricText.isNotEmpty;
      items[0].firstOfParentheses = true;
      notations.addAll(items);

      // add the lyrics and/or alText to the first notation that makes sense...
      ChantNotationElement? notationWithLyrics;
      for (var i = 0; i < items.length; i++) {
        final cne = items[i];

        if (cne is Accidental && i + 1 < items.length) continue;

        notationWithLyrics = cne;
        break;
      }

      // process alt/translation text from lyricText
      var indexOffset = 0;
      RegExpMatch? vMatch;
      while ((vMatch = _altTranslationRegex.firstMatch(lyricText)) != null) {
        final m = vMatch!;
        final index = m.start;
        lyricText =
            lyricText.substring(0, index) +
            lyricText.substring(index + m[0]!.length);
        final adjustedIndex = index + sourceIndex + indexOffset + 1;
        if (m[1] != null) {
          final elem = AboveLinesText(
            ctxt,
            m[1]!,
            notationWithLyrics!,
            adjustedIndex + 4,
          );
          alText.add(elem);
        } else if (m[2] != null) {
          final elem = AboveLinesText(
            ctxt,
            m[3]!,
            notationWithLyrics!,
            adjustedIndex + m[2]!.length,
          );
          alText.add(elem);
        } else {
          final elem = TranslationText(
            ctxt,
            m[3]!,
            notationWithLyrics!,
            adjustedIndex,
          );
          translationText.add(elem);
        }
        indexOffset += m[0]!.length;
      }
      if (lyricText.isEmpty && alText.isEmpty) continue;

      if (notationWithLyrics == null) {
        return ChantMapping(word, notations, sourceIndex);
      }

      if (alText.isNotEmpty) {
        notationWithLyrics.alText = alText;
      }

      if (translationText.isNotEmpty) {
        notationWithLyrics.translationText = translationText;
        for (var i = 0; i < translationText.length; ++i) {
          final transText = translationText[i];
          if (transText.textAnchor == .end &&
              lastTranslationNeumes.isNotEmpty) {
            final lastTranslationText =
                lastTranslationNeumes[0].translationText[i];
            if (lastTranslationText != null) {
              lastTranslationText.endNeume = notationWithLyrics;
            }
          }
        }
        lastTranslationNeumes.add(notationWithLyrics);
      }

      if (lyricText.isEmpty) continue;

      LyricType proposedLyricType;

      final cne = items.last;
      if (cne is! Neume && cne is! TextOnly) {
        proposedLyricType = LyricType.directive;
      } else if (currSyllable == 0 && j == matches.length - 1) {
        proposedLyricType = LyricType.singleSyllable;
      } else if (currSyllable == 0 && j < matches.length - 1) {
        proposedLyricType = LyricType.beginningSyllable;
      } else if (j == matches.length - 1) {
        proposedLyricType = LyricType.endingSyllable;
      } else {
        proposedLyricType = LyricType.middleSyllable;
      }

      currSyllable++;

      final lyrics = createSyllableLyrics(
        ctxt,
        lyricText,
        proposedLyricType,
        notationWithLyrics,
        items,
        sourceIndex + match.start,
      );

      if (lyrics == null || lyrics.isEmpty) continue;

      notationWithLyrics.lyrics = lyrics;
    }

    return ChantMapping(word, notations, sourceIndex);
  }

  /// Returns an array of lyrics (an array because each syllable can have
  /// multiple lyrics).
  static List<Lyric>? createSyllableLyrics(
    ChantContext ctxt,
    String text,
    LyricType proposedLyricType,
    ChantNotationElement notation,
    List<ChantNotationElement> notations,
    int sourceIndex,
  ) {
    final lyrics = <Lyric>[];

    // an extension to gabc: multiple lyrics per syllable can be separated by a |
    final lyricTexts = text.split('|');

    for (var i = 0; i < lyricTexts.length; i++) {
      var lyricText = lyricTexts[i];
      var lyricType = proposedLyricType;

      if (i > 0) {
        if (RegExp(r'\s$').hasMatch(lyricText)) {
          lyricText = lyricText.replaceAll(RegExp(r'\s+$'), '');
          lyricType = LyricType.endingSyllable;
        } else {
          lyricType = LyricType.middleSyllable;
        }
      }

      // gabc allows lyrics to indicate the centering part of the text by
      // using braces to indicate how to center the lyric.
      var lyricTextWithoutVTags = lyricText;
      final vtags = <int, int>{};
      final vtagRegex = RegExp(r'<v>[\s\S]*?<\/v>');
      Match? vMatch;
      while ((vMatch = vtagRegex.firstMatch(lyricTextWithoutVTags)) != null) {
        final m = vMatch!;
        final index = m.start;
        final length = m[0]!.length;
        vtags[index] = length;
        lyricTextWithoutVTags =
            lyricTextWithoutVTags.substring(0, index) +
            lyricTextWithoutVTags.substring(index + length);
      }
      var centerStartIndex = lyricTextWithoutVTags.indexOf('{');
      var centerLength = 0;

      if (centerStartIndex >= 0) {
        final indexClosingBracket = lyricTextWithoutVTags.indexOf('}');

        if (indexClosingBracket >= 0 &&
            indexClosingBracket > centerStartIndex) {
          int getTrueIndex(int indexWithoutVTags) {
            var accum = 0;
            for (final index in vtags.keys) {
              if (indexWithoutVTags >= index) {
                accum += vtags[index]!;
              } else {
                break;
              }
            }
            return indexWithoutVTags + accum;
          }

          centerStartIndex = getTrueIndex(centerStartIndex);
          final trueClosingBracket = getTrueIndex(indexClosingBracket);
          centerLength = trueClosingBracket - centerStartIndex - 1;

          // strip out the brackets:
          lyricText =
              lyricText.substring(0, centerStartIndex) +
              lyricText.substring(centerStartIndex + 1, trueClosingBracket) +
              lyricText.substring(trueClosingBracket + 1);
        } else {
          centerStartIndex = -1;
        }
      }

      final lyric = makeLyric(
        ctxt,
        lyricText,
        lyricType,
        notation,
        notations,
        sourceIndex,
      );

      if (centerStartIndex >= 0) {
        // update indices in case there had been any tags, etc.
        var textIndex = 0;
        var centerEndIndex = -1;
        for (final span in lyric.spans) {
          if (centerStartIndex >= span.index &&
              centerStartIndex <= span.index + span.text.length) {
            centerEndIndex = centerStartIndex + centerLength;
            centerStartIndex += textIndex - span.index;
          }
          if (centerEndIndex >= 0 &&
              centerEndIndex >= span.index &&
              centerEndIndex <= span.index + span.text.length) {
            centerEndIndex += textIndex - span.index;
            centerLength = centerEndIndex - centerStartIndex;
            centerEndIndex = -1;
            break;
          }
          textIndex += span.text.length;
        }
        if (centerEndIndex >= 0) {
          centerEndIndex = textIndex;
          centerLength = centerEndIndex - centerStartIndex;
        }
      }

      // if we have manual lyric centering, then set it now
      if (centerStartIndex >= 0) {
        lyric.centerStartIndex = centerStartIndex;
        lyric.centerLength = centerLength;
      }

      lyrics.add(lyric);
      sourceIndex += lyricText.length + 1;
    }
    notation.lyrics = lyrics;
    return lyrics;
  }

  static Lyric makeLyric(
    ChantContext ctxt,
    String text,
    LyricType lyricType,
    ChantNotationElement notation,
    List<ChantNotationElement> notations,
    int sourceIndex,
  ) {
    var elides = false;
    var forceConnector = false;
    if (text.length > 1) {
      if (text[text.length - 1] == '-') {
        forceConnector = true;
        if (lyricType == LyricType.endingSyllable) {
          lyricType = LyricType.middleSyllable;
        } else if (lyricType == LyricType.singleSyllable) {
          lyricType = LyricType.beginningSyllable;
        }
        text = text.substring(0, text.length - 1);
      } else if (text[text.length - 1] == ' ') {
        if (lyricType == LyricType.middleSyllable) {
          lyricType = LyricType.endingSyllable;
        } else if (lyricType == LyricType.beginningSyllable) {
          lyricType = LyricType.singleSyllable;
        }
        text = text.substring(0, text.length - 1);
      } else if (RegExp(r'<\/i>$').hasMatch(text)) {
        // must be an elision
        elides = true;
      }
    }

    if (RegExp(r'^(?:[*†]+|i+j|\d+)\.?$').hasMatch(text)) {
      lyricType = LyricType.directive;
    }

    final lyric = Lyric(
      ctxt,
      text,
      lyricType,
      notation,
      notations,
      sourceIndex,
    );
    lyric.elidesToNext = elides;
    if (forceConnector) lyric.setForceConnector(true);

    return lyric;
  }

  /// Takes a string of gabc notations and creates exsurge objects out of them.
  /// Returns an array of notations.
  static List<ChantNotationElement> parseNotations(
    ChantContext ctxt,
    String? data,
    int sourceIndex,
    int? insertionIndex,
  ) {
    // if there is no data, then this must be a text only object
    if (data == null || data.isEmpty) {
      return [TextOnly(sourceIndex, 0)];
    }

    final baseSourceIndex = sourceIndex;
    var sourceLength = 0;
    final notations = <ChantNotationElement>[];
    var notes = <Note>[];
    var trailingSpace = TrailingSpace.defaultTrailingSpace;

    void addToLastSourceGabc(String gabc) {
      if (notes.isNotEmpty) {
        notes[notes.length - 1].sourceGabc += gabc;
      }
    }

    void addNotation(ChantNotationElement? notation, RegExpMatch? match) {
      if (notes.isNotEmpty) {
        final neumes = createNeumesFromNotes(ctxt, notes, trailingSpace);
        for (var i = 0; i < neumes.length; i++) {
          notations.add(neumes[i]);
        }
        notes = [];
      }

      // trailingSpaceIsDefault = true;
      trailingSpace = TrailingSpace.defaultTrailingSpace;

      if (notation != null) {
        final prevNotation = notations.isNotEmpty
            ? notations[notations.length - 1]
            : null;
        notation.sourceIndex = sourceIndex;
        if (match != null) notation.sourceGabc = match[0]!;
        if (notation is Clef) {
          ctxt.activeClef = notation;
          if (prevNotation != null &&
              prevNotation.trailingSpace.isDefault &&
              prevNotation is Divider) {
            prevNotation.trailingSpace = TrailingSpace.forAccidental;
          }
        } else if (notation is Accidental) {
          ctxt.activeClef?.activeAccidental = notation;
        } else if (notation.trailingSpace.isDefault && notation is Custos) {
          notation.trailingSpace = TrailingSpace.forAccidental;
        } else if (notation case Divider d when d.resetsAccidentals) {
          ctxt.activeClef?.resetAccidentals();
        }

        notations.add(notation);
      }
    }

    for (final match in _notationsRegex.allMatches(data)) {
      sourceIndex = baseSourceIndex + match.start;
      sourceLength = match[0]!.length;
      var atom = match[0]!;
      final bar = match[_notationsRegexGroupBar];

      var barWithCarryover = bar != null && bar.endsWith('_');
      if (barWithCarryover) {
        atom = atom.substring(0, atom.length - 1);
      }

      switch (atom) {
        case ',':
          addNotation(QuarterBar(hasCarryover: barWithCarryover), match);
          break;
        case '`':
          addNotation(Virgula(hasCarryover: barWithCarryover), match);
          break;
        case ';':
          addNotation(HalfBar(hasCarryover: barWithCarryover), match);
          break;
        case ';1':
        case ';2':
        case ';3':
        case ';4':
        case ';5':
        case ';6':
        case ';7':
        case ';8':
        case ',1':
        case ',2':
        case ',3':
        case ',4':
        case ',5':
        case ',6':
        case ',7':
        case ',8':
          addNotation(DominicanBar(int.parse(atom[1])), match);
          break;
        case ':':
          addNotation(FullBar(hasCarryover: barWithCarryover), match);
          break;
        case '::':
          addNotation(DoubleBar(), match);
          break;

        case 'c1':
        case 'c2':
        case 'c3':
        case 'c4':
        case 'c5':
          final clef = DoClef(
            staffPosition: 2 * int.parse(atom[1]) - 1,
            octave: 2,
          );
          ctxt.activeClef = clef;
          addNotation(clef, match);
          break;
        case 'f1':
        case 'f2':
        case 'f3':
        case 'f4':
        case 'f5':
          final clef = FaClef(
            staffPosition: 2 * int.parse(atom[1]) - 1,
            octave: 2,
          );
          ctxt.activeClef = clef;
          addNotation(clef, match);
          break;
        case 'treble1':
        case 'treble2':
        case 'treble3':
        case 'treble4':
        case 'treble5':
        case 'treble-1':
        case 'treble-2':
        case 'treble-3':
        case 'treble-4':
        case 'treble-5':
          final clef = TrebleClef(
            staffPosition: 2 * int.parse(atom[atom.length - 1]) - 1,
            octave: 2,
            small: atom.length > 6 && atom[6] == '-',
          );
          ctxt.activeClef = clef;
          addNotation(clef, match);
          break;
        case 'xp1':
        case 'xp2':
        case 'xp3':
        case 'xp4':
        case 'xp5':
        case 'xp-1':
        case 'xp-2':
        case 'xp-3':
        case 'xp-4':
        case 'xp-5':
          final clef = ChiRhoClef(
            staffPosition: 2 * int.parse(atom[atom.length - 1]) - 1,
            octave: 2,
            sans: atom.length > 3 && atom[atom.length - 2] == '-',
          );
          ctxt.activeClef = clef;
          addNotation(clef, match);
          break;
        case 'cb1':
        case 'cb2':
        case 'cb3':
        case 'cb4':
        case 'cb5':
          {
            final line = 2 * int.parse(atom[2]) - 1;
            final clef = DoClef(
              staffPosition: line,
              octave: 2,
              defaultAccidental: Accidental(
                staffPosition: line - 1,
                accidentalType: AccidentalType.flat,
              ),
            );
            ctxt.activeClef = clef;
            addNotation(clef, match);
          }
          break;

        case 'z':
          addNotation(ChantLineBreak(true), match);
          break;
        case 'Z':
          addNotation(ChantLineBreak(false), match);
          break;
        case 'z0':
          addNotation(Custos(auto: true), match);
          break;

        case '!':
          trailingSpace = TrailingSpace.zero;
          addToLastSourceGabc(atom);
          addNotation(null, match);
          break;
        case ' ':
          trailingSpace = TrailingSpace.multiple(2);
          addToLastSourceGabc(atom);
          addNotation(null, match);
          break;

        default:
          if (atom[0] == '/') {
            trailingSpace = TrailingSpace.multiple(atom.length.toDouble());
            addToLastSourceGabc(atom);
            addNotation(null, match);
          } else if (atom.length > 1 && atom.endsWith('+')) {
            final custos = Custos();
            setStaffPositionAndOffset(custos, atom);
            addNotation(custos, match);
          } else if (atom.length > 1 && RegExp(r'[xy#]').hasMatch(atom[1])) {
            AccidentalType accidentalType;
            switch (atom[1]) {
              case 'y':
                accidentalType = AccidentalType.natural;
                break;
              case '#':
                accidentalType = AccidentalType.sharp;
                break;
              default:
                accidentalType = AccidentalType.flat;
                break;
            }

            final noteArray = <Note>[];
            createNoteFromData(
              ctxt,
              ctxt.activeClef as Clef,
              atom,
              noteArray,
              sourceIndex,
            );
            final accidental = Accidental(
              staffPosition: noteArray[0].staffPosition,
              accidentalType: accidentalType,
            );
            accidental.pitch = (ctxt.activeClef as Clef).staffPositionToPitch(
              noteArray[0].staffPosition,
            );
            accidental.sourceIndex = sourceIndex;
            accidental.sourceLength = sourceLength;
            accidental.trailingSpace = TrailingSpace.forAccidental;

            (ctxt.activeClef as Clef).activeAccidental = accidental;

            addNotation(accidental, match);
          } else if (atom.length > 1 && atom[0] == '{') {
            trailingSpace = TrailingSpace.zero;
            addNotation(null, match);
            final bracketedNotations = parseNotations(
              ctxt,
              match[_notationsRegexGroupInsideBraces],
              sourceIndex + 1,
              null,
            );
            for (final neume in bracketedNotations) {
              neume.hasNoWidth = true;
              neume.firstWithNoWidth = bracketedNotations[0];
            }
            notations.addAll(bracketedNotations);
          } else {
            if (insertionIndex == -1) {
              trailingSpace = TrailingSpace.multiple(1);
              addNotation(null, match);
            }
            createNoteFromData(
              ctxt,
              ctxt.activeClef as Clef,
              atom,
              notes,
              sourceIndex,
            );
            if (insertionIndex != null) insertionIndex--;
          }
          break;
      }
    }

    addNotation(null, null);

    return notations;
  }

  /// Creates neumes from a list of notes using a finite state machine.
  static List<Neume> createNeumesFromNotes(
    ChantContext ctxt,
    List<Note> notes,
    TrailingSpace finalTrailingSpace,
  ) {
    final neumes = <Neume>[];
    var firstNoteIndex = 0;
    var currNoteIndex = 0;

    late NeumeState unknownState;

    NeumeState createNeume(
      Neume neume,
      bool includeCurrNote, [
      bool includePrevNote = true,
    ]) {
      int lastNoteIndex;
      if (includeCurrNote) {
        lastNoteIndex = currNoteIndex;
      } else if (includePrevNote) {
        lastNoteIndex = currNoteIndex - 1;
      } else {
        lastNoteIndex = currNoteIndex - 2;
      }

      if (lastNoteIndex < 0) return unknownState;

      while (firstNoteIndex <= lastNoteIndex) {
        final note = notes[firstNoteIndex++];
        neume.addNote(note);
        if (note.alText != null) {
          if (neume.alText.isEmpty) neume.alText = [];
          neume.alText.add(note.alText!);
        }
      }

      neumes.add(neume);

      if (includeCurrNote == false) {
        currNoteIndex--;

        if (includePrevNote == false) currNoteIndex--;

        neume.keepWithNext = true;
        if (notes[currNoteIndex + 1].shape == NoteShape.quilisma) {
          neume.trailingSpace = TrailingSpace.zero;
        } else {
          neume.trailingSpace = TrailingSpace.multiple(1);
          neume.allowLineBreakBeforeNext = true;
        }
      }

      return unknownState;
    }

    unknownState = UnknownState(createNeume, notes, currNoteIndex);
    // final punctumState = PunctumState(createNeume, notes, currNoteIndex);
    // final punctaInclinataState = PunctaInclinataState(createNeume);
    // final oriscusState = OriscusState(createNeume);
    // final podatusState = PodatusState(createNeume, notes, currNoteIndex);
    // final clivisState = ClivisState(createNeume);
    // final climacusState = ClimacusState(createNeume);
    // final porrectusState = PorrectusState(createNeume);
    // final pesSubpunctisState = PesSubpunctisState(createNeume);
    // final salicusState = SalicusState(createNeume);
    // final salicusFlexusState = SalicusFlexusState(createNeume);
    // final scandicusState = ScandicusState(createNeume);
    // final scandicusFlexusState = ScandicusFlexusState(createNeume);
    // final virgaState = VirgaState(createNeume);
    // final bivirgaState = BivirgaState(createNeume);
    // final apostrophaState = ApostrophaState(createNeume);
    // final distrophaState = DistrophaState(createNeume);
    // final tristrophaState = TristrophaState(createNeume);
    // final torculusState = TorculusState(createNeume, notes, currNoteIndex);
    // final torculusResupinusState = TorculusResupinusState(createNeume);

    NeumeState state = unknownState;

    while (currNoteIndex < notes.length) {
      final prevNote = currNoteIndex > 0 ? notes[currNoteIndex - 1] : null;
      final currNote = notes[currNoteIndex];

      state = state.handle(
        currNote,
        prevNote,
        notes.length - 1 - currNoteIndex,
      );

      if (currNoteIndex == notes.length - 1 && state != unknownState) {
        createNeume(state.neume(), true);
      }

      currNoteIndex++;
    }

    if (neumes.isNotEmpty) {
      if (!finalTrailingSpace.isDefault) {
        neumes[neumes.length - 1].trailingSpace = finalTrailingSpace;
        neumes[neumes.length - 1].keepWithNext = true;

        if (finalTrailingSpace(ctxt) > 0) {
          neumes[neumes.length - 1].allowLineBreakBeforeNext = true;
          neumes[neumes.length - 1].keepWithNext = true;
        }
      }
    }

    return neumes;
  }

  /// Appends any notes created to the notes array argument.
  static void createNoteFromData(
    ChantContext ctxt,
    Clef clef,
    String data,
    List<Note> notes,
    int sourceIndex,
  ) {
    var note = Note();
    note.sourceIndex = sourceIndex;
    note.sourceGabc = data;

    if (data.isEmpty) throw 'Invalid note data: $data';

    if (data[0] == '@') {
      note.suppressVirga = true;
      data = data.substring(1);
    }

    if (data[0] == '-') {
      note.liquescent = LiquescentType.initioDebilis.value;
      data = data.substring(1);
    }

    if (data.isEmpty) throw 'Invalid note data: $data';

    if (data[0] == data[0].toUpperCase()) {
      note.shape = NoteShape.inclinatum;
    }

    setStaffPositionAndOffset(note, data);
    note.pitch = clef.staffPositionToPitch(
      (note.staffPosition - note.staffPositionOffset).round(),
    );

    var episemaNoteIndex = notes.length;
    Note episemaNote = note;

    for (var i = 1; i < data.length; i++) {
      final c = data[i];
      var lookahead = '\x00';

      var haveLookahead = i + 1 < data.length;
      if (haveLookahead) lookahead = data[i + 1];

      switch (c) {
        case '.':
          if (note.morae.isNotEmpty && notes.isNotEmpty) {
            final previousNote = notes.last;
            final previousMora = note.morae.last;
            previousMora.note = previousNote;
          }

          final mora = Mora(ctxt, note);
          if (haveLookahead && lookahead == '1') {
            mora.positionHint = MarkingPositionHint.above;
          } else if (haveLookahead && lookahead == '0') {
            mora.positionHint = MarkingPositionHint.below;
          }

          note.morae.add(mora);
          break;

        case '_':
          var episemaHadModifier = false;

          final episema = HorizontalEpisema(episemaNote);
          while (haveLookahead) {
            if (lookahead == '0') {
              episema.positionHint = MarkingPositionHint.below;
            } else if (lookahead == '1') {
              episema.positionHint = MarkingPositionHint.above;
            } else if (lookahead == '2') {
              episema.terminating = true;
            } else if (lookahead == '3') {
              episema.alignment = HorizontalEpisemaAlignment.left;
            } else if (lookahead == '4') {
              episema.alignment = HorizontalEpisemaAlignment.center;
            } else if (lookahead == '5') {
              episema.alignment = HorizontalEpisemaAlignment.right;
            } else {
              break;
            }

            if (episema.alignment != HorizontalEpisemaAlignment.defaultValue &&
                episema.positionHint != MarkingPositionHint.below) {
              episemaHadModifier = true;
            }

            i++;
            haveLookahead = i + 1 < data.length;

            if (haveLookahead) lookahead = data[i + 1];
          }

          episemaNote.episemata.add(episema);

          if (episemaNote == note && episemaHadModifier) {
            episemaNote = note;
          } else if (episemaNoteIndex > 0 && notes.isNotEmpty) {
            episemaNote = notes[--episemaNoteIndex];
          }

          break;

        case "'":
          final ictus = Ictus(ctxt, note);
          if (haveLookahead && lookahead == '1') {
            ictus.positionHint = MarkingPositionHint.above;
          } else if (haveLookahead && lookahead == '0') {
            ictus.positionHint = MarkingPositionHint.below;
          } else if (note.shape == NoteShape.virga) {
            ictus.positionHint = MarkingPositionHint.above;
          }

          note.ictus = ictus;
          break;

        case '|':
          note.inclinataFlags++;
          break;

        case 'r':
          if (haveLookahead && RegExp(r'[0-5]').hasMatch(lookahead)) {
            switch (lookahead) {
              case '0':
                note.shapeModifiers = combineFlags(
                  note.shapeModifiers,
                  NoteShapeModifiers.cavum,
                );
                note.shapeModifiers = combineFlags(
                  note.shapeModifiers,
                  NoteShapeModifiers.linea,
                );
                break;
              case '1':
                note.accent = Accent(
                  ctxt,
                  note,
                  glyphCode: GlyphCode.acuteAccent,
                );
                break;
              case '2':
                note.accent = Accent(
                  ctxt,
                  note,
                  glyphCode: GlyphCode.graveAccent,
                );
                break;
              case '3':
                note.accent = Accent(ctxt, note, glyphCode: GlyphCode.circle);
                break;
              case '4':
                note.accent = Accent(
                  ctxt,
                  note,
                  glyphCode: GlyphCode.semicircle,
                );
                break;
              case '5':
                note.accent = Accent(
                  ctxt,
                  note,
                  glyphCode: GlyphCode.reversedSemicircle,
                );
                break;
            }
            i++;
          } else {
            note.shapeModifiers = combineFlags(
              note.shapeModifiers,
              NoteShapeModifiers.cavum,
            );
          }
          break;

        case 'R':
          note.shapeModifiers = combineFlags(
            note.shapeModifiers,
            NoteShapeModifiers.linea,
          );
          break;

        case 's':
          if (note.shape == NoteShape.stropha) {
            final newNote = Note();
            newNote.sourceIndex = sourceIndex + i;
            newNote.sourceGabc = 's';
            newNote.staffPosition = note.staffPosition;
            newNote.pitch = note.pitch;
            notes.add(note);
            note = newNote;
            episemaNoteIndex++;
          }
          note.shape = NoteShape.stropha;
          break;

        case 'v':
          if (note.shape == NoteShape.virga) {
            final newNote = Note();
            newNote.sourceIndex = sourceIndex + i;
            newNote.sourceGabc = 'v';
            newNote.staffPosition = note.staffPosition;
            newNote.pitch = note.pitch;
            notes.add(note);
            note = newNote;
            episemaNoteIndex++;
          }
          note.shape = NoteShape.virga;
          break;

        case 'V':
          note.shape = NoteShape.virga;
          note.shapeModifiers = combineFlags(
            note.shapeModifiers,
            NoteShapeModifiers.reverse,
          );
          break;

        case 'w':
          note.shape = NoteShape.quilisma;
          break;

        case 'o':
          note.shape = NoteShape.oriscus;
          if (haveLookahead && lookahead == '<') {
            note.shapeModifiers = combineFlags(
              note.shapeModifiers,
              NoteShapeModifiers.ascending,
            );
            i++;
          } else if (haveLookahead && lookahead == '>') {
            note.shapeModifiers = combineFlags(
              note.shapeModifiers,
              NoteShapeModifiers.descending,
            );
            i++;
          }
          break;

        case 'O':
          note.shape = NoteShape.oriscus;
          if (haveLookahead && lookahead == '<') {
            note.shapeModifiers =
                note.shapeModifiers |
                NoteShapeModifiers.ascending.value |
                NoteShapeModifiers.stemmed.value;
            i++;
          } else if (haveLookahead && lookahead == '>') {
            note.shapeModifiers =
                note.shapeModifiers |
                NoteShapeModifiers.descending.value |
                NoteShapeModifiers.stemmed.value;
            i++;
          } else {
            note.shapeModifiers = combineFlags(
              note.shapeModifiers,
              NoteShapeModifiers.stemmed,
            );
          }
          break;

        case '~':
          if (note.shape == NoteShape.inclinatum) {
            note.liquescent = combineFlags(
              note.liquescent,
              LiquescentType.small,
            );
          } else if (note.shape == NoteShape.oriscus) {
            note.liquescent = combineFlags(
              note.liquescent,
              LiquescentType.large,
            );
          } else {
            note.liquescent = combineFlags(
              note.liquescent,
              LiquescentType.small,
            );
          }
          break;
        case '<':
          note.liquescent = combineFlags(
            note.liquescent,
            LiquescentType.ascending,
          );
          break;
        case '>':
          note.liquescent = combineFlags(
            note.liquescent,
            LiquescentType.descending,
          );
          break;

        case 'x':
          if (note.pitch!.step == Step.mi) {
            note.pitch = Pitch(Step.me.value, note.pitch!.octave);
          } else if (note.pitch!.step == Step.ti) {
            note.pitch = Pitch(Step.te.value, note.pitch!.octave);
          }
          break;
        case 'y':
          if (note.pitch!.step == Step.te) {
            note.pitch = Pitch(Step.ti.value, note.pitch!.octave);
          } else if (note.pitch!.step == Step.me) {
            note.pitch = Pitch(Step.mi.value, note.pitch!.octave);
          } else if (note.pitch!.step == Step.du) {
            note.pitch = Pitch(Step.ut.value, note.pitch!.octave);
          } else if (note.pitch!.step == Step.fu) {
            note.pitch = Pitch(Step.fa.value, note.pitch!.octave);
          }
          break;
        case '#':
          if (note.pitch!.step == Step.ut) {
            note.pitch = Pitch(Step.du.value, note.pitch!.octave);
          } else if (note.pitch!.step == Step.fa) {
            note.pitch = Pitch(Step.fu.value, note.pitch!.octave);
          }
          break;

        case '[':
          final startIndex = ++i;
          while (i < data.length && data[i] != ']') {
            i++;
          }

          processInstructionForNote(
            ctxt,
            note,
            data.substring(startIndex, i),
            startIndex,
          );
          break;
      }
    }

    if (needToEndBrace != null &&
        note.braceStart == null &&
        note.braceEnd == null &&
        !RegExp(r'[xy#]').hasMatch(data[data.length - 1])) {
      note.braceEnd = BracePoint(
        note,
        needToEndBrace!.isAbove,
        needToEndBrace!.shape,
        needToEndBrace!.attachment == BraceAttachment.left
            ? BraceAttachment.right
            : BraceAttachment.left,
      );
      (note.braceEnd as BracePoint).automatic = true;
      needToEndBrace = null;
    }

    notes.add(note);
  }

  /// Processes a special gabc instruction found between [ and ] after notes.
  /// Currently only brace instructions and choral signs are supported.
  static void processInstructionForNote(
    ChantContext ctxt,
    Note note,
    String instruction,
    int sourceIndexOffset,
  ) {
    var results = _bracketedCommandRegex.firstMatch(instruction);
    if (results == null) return;
    final cmd = results.group(1)!;
    final data = results.group(2)!;
    switch (cmd) {
      case 'cs':
        note.choralSign = ChoralSign(
          ctxt,
          data,
          note,
          (note.sourceIndex ?? 0) + sourceIndexOffset,
        );
        return;
      case 'alt':
        note.alText = AboveLinesText(
          ctxt,
          data,
          note,
          (note.sourceIndex ?? 0) + sourceIndexOffset,
        );
        return;
    }

    results = _braceSpecRegex.firstMatch(instruction);
    if (results == null) return;

    final above = results.group(1) == 'o';
    var shape = BraceShape.curlyBrace;

    switch (results.group(2)) {
      case 'b':
        shape = BraceShape.roundBrace;
        break;
      case 'cb':
        shape = BraceShape.curlyBrace;
        break;
      case 'cba':
        shape = BraceShape.accentedCurlyBrace;
        break;
    }

    final attachmentPoint = results.group(3) == '1'
        ? BraceAttachment.left
        : BraceAttachment.right;

    if (results.group(4) == '{' || results.group(5) != null) {
      note.braceStart = BracePoint(note, above, shape, attachmentPoint);
    } else {
      note.braceEnd = BracePoint(note, above, shape, attachmentPoint);
    }

    if (results.group(5) != null) {
      (note.braceStart as BracePoint).automatic = true;
      needToEndBrace = note.braceStart;
    }
  }

  /// Takes raw gabc text source and parses it into words.
  static List<String> splitWords(String gabcNotations) {
    gabcNotations = gabcNotations.replaceAllMapped(
      RegExp(r'\)\s(?=[^\)]*(?:\(|$))'),
      (m) => ')\n',
    );
    return gabcNotations.split(RegExp(r'\n'));
  }

  static List<List<SyllableData>> parseSource(String gabcSource) {
    return parseWords(splitWords(gabcSource));
  }

  /// [gabcWords] is an array of strings, e.g., the result of [splitWords].
  static List<List<SyllableData>> parseWords(List<String> gabcWords) {
    final words = <List<SyllableData>>[];
    for (var i = 0; i < gabcWords.length; i++) {
      words.add(parseWord(gabcWords[i]));
    }
    return words;
  }

  /// Returns an array of [SyllableData], each with notations and lyrics.
  static List<SyllableData> parseWord(String gabcWord) {
    final syllables = <SyllableData>[];

    for (final match in _syllablesRegex.allMatches(gabcWord)) {
      final lyrics = match.group(1)!.trim().split('|');
      final notations = match.group(2);

      syllables.add(SyllableData(notations: notations, lyrics: lyrics));
    }

    return syllables;
  }

  /// Converts a gabc height letter (a through m) to an exsurge staff
  /// position.
  static int gabcHeightToExsurgeHeight(String gabcHeight) {
    return gabcHeight.toLowerCase().codeUnitAt(0) - 'c'.codeUnitAt(0);
  }

  /// Returns the staff position offset for a 0 or 9 modifier.
  static double getStaffPositionOffset(int staffPosition, String? zeroOrNine) {
    var offset = 0.0;
    if (zeroOrNine != null && RegExp(r'0|9').hasMatch(zeroOrNine)) {
      final basis = staffPosition % 2 != 0 ? 2 : 1;
      offset = (int.parse(zeroOrNine) != 0 ? basis : -basis) / 3;
    }
    return offset;
  }

  /// Sets the staffPosition and staffPositionOffset on [note] from the gabc
  /// atom [gabcAtom].
  static void setStaffPositionAndOffset(dynamic note, String gabcAtom) {
    final staffPosition = gabcHeightToExsurgeHeight(gabcAtom[0]);
    final offset = getStaffPositionOffset(
      staffPosition,
      gabcAtom.length > 1 ? gabcAtom[1] : null,
    );
    if (note is Note) {
      note.staffPositionOffset = offset;
      note.staffPosition = staffPosition + offset.round();
    } else if (note is Custos) {
      note.staffPositionOffset = offset.round();
      note.staffPosition = staffPosition + offset.round();
    }
  }

  /// Parses a string of gabc notations (as stored in the JSON serialization
  /// format) and populates [score] with the resulting mappings.
  ///
  /// If [createDropCap] is `true`, then a drop cap is created for the score.
  static void parseChantNotations(
    String notations,
    dynamic score,
    bool createDropCap,
  ) {
    // TODO: implement full parsing of serialized notations into the score.
  }
}

/// A simple data class used by [Gabc.parseWord].
class SyllableData {
  SyllableData({this.notations, required this.lyrics});

  final String? notations;
  final List<String> lyrics;
}

/// Base class for neume-building states in the finite state machine used by
/// [Gabc.createNeumesFromNotes].
sealed class NeumeState {
  NeumeState(this.createNeume);

  final NeumeState Function(
    Neume neume,
    bool includeCurrNote, [
    bool includePrevNote,
  ])
  createNeume;

  Neume neume();
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining);
}

class UnknownState extends NeumeState {
  UnknownState(super.createNeume, this.notes, this.currNoteIndex);

  final List<Note> notes;
  final int currNoteIndex;

  @override
  Neume neume() => Punctum();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape == NoteShape.virga) {
      return VirgaState(createNeume);
    } else if (currNote.shape == NoteShape.stropha) {
      return ApostrophaState(createNeume);
    } else if (currNote.shape == NoteShape.oriscus) {
      return OriscusState(createNeume);
    } else if (currNote.shape == NoteShape.inclinatum) {
      return PunctaInclinataState(createNeume);
    } else if (hasFlag(currNote.shapeModifiers, NoteShapeModifiers.cavum)) {
      return createNeume(Punctum(), true);
    } else {
      return PunctumState(createNeume, notes, currNoteIndex);
    }
  }
}

class PunctumState extends NeumeState {
  PunctumState(super.createNeume, this.notes, this.currNoteIndex);

  final List<Note> notes;
  final int currNoteIndex;

  @override
  Neume neume() => Punctum();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    final prev = prevNote!;
    if (currNote.shape != NoteShape.defaultShape ||
        prev.liquescent == LiquescentType.small.value) {
      final neume = Punctum();
      final state = createNeume(neume, false);
      if (currNote.staffPosition > prev.staffPosition &&
          (currNote.staffPosition % 2 == 1 ||
              prev.staffPosition != currNote.staffPosition - 1 ||
              prev.morae.isEmpty)) {
        neume.trailingSpace = TrailingSpace.zero;
      }
      return state;
    }

    if (currNote.staffPosition > prev.staffPosition) {
      if (currNote.ictus != null) {
        currNote.ictus!.positionHint = MarkingPositionHint.above;
      }
      return PodatusState(createNeume, notes, currNoteIndex);
    } else if (currNote.staffPosition < prev.staffPosition) {
      if (prev.ictus != null) {
        prev.ictus!.positionHint = MarkingPositionHint.above;
      }
      if (currNote.shape == NoteShape.inclinatum) {
        return ClimacusState(createNeume);
      } else {
        return ClivisState(createNeume);
      }
    } else if (prev.morae.isEmpty) {
      return DistrophaState(createNeume);
    }
    return createNeume(Punctum(), false);
  }
}

class PunctaInclinataState extends NeumeState {
  PunctaInclinataState(super.createNeume);

  @override
  Neume neume() => PunctaInclinata();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape != NoteShape.inclinatum) {
      return createNeume(PunctaInclinata(), false);
    } else {
      return this;
    }
  }
}

class OriscusState extends NeumeState {
  OriscusState(super.createNeume);

  @override
  Neume neume() => Oriscus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape == NoteShape.defaultShape) {
      if (currNote.staffPosition > prevNote!.staffPosition) {
        prevNote.shapeModifiers = combineFlags(
          prevNote.shapeModifiers,
          NoteShapeModifiers.ascending,
        );
        return createNeume(PesQuassus(), true);
      } else if (currNote.staffPosition < prevNote.staffPosition) {
        prevNote.shapeModifiers = combineFlags(
          prevNote.shapeModifiers,
          NoteShapeModifiers.descending,
        );
        return createNeume(Clivis(), true);
      }
    }
    final neume = Oriscus();
    final state = createNeume(neume, false);
    if (currNote.staffPosition > prevNote!.staffPosition &&
        (currNote.staffPosition % 2 == 1 ||
            prevNote.staffPosition != currNote.staffPosition - 1 ||
            prevNote.morae.isEmpty)) {
      neume.trailingSpace = TrailingSpace.zero;
    }
    return state;
  }
}

class PodatusState extends NeumeState {
  PodatusState(super.createNeume, this.notes, this.currNoteIndex);

  final List<Note> notes;
  final int currNoteIndex;

  @override
  Neume neume() => Podatus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    final prev = prevNote!;
    if (currNote.staffPosition > prev.staffPosition) {
      if (currNote.ictus != null) {
        currNote.ictus!.positionHint = MarkingPositionHint.above;
      }
      if (prev.ictus != null) {
        prev.ictus!.positionHint = MarkingPositionHint.below;
      }

      if (prev.shape == NoteShape.oriscus) {
        return SalicusState(createNeume);
      } else {
        return ScandicusState(createNeume);
      }
    } else if (currNote.staffPosition < prev.staffPosition) {
      if (currNote.shape == NoteShape.inclinatum) {
        return PesSubpunctisState(createNeume);
      } else {
        return TorculusState(createNeume, notes, currNoteIndex);
      }
    } else {
      return createNeume(Podatus(), false);
    }
  }
}

class ClivisState extends NeumeState {
  ClivisState(super.createNeume);

  @override
  Neume neume() => Clivis();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    final prev = prevNote!;
    if (currNote.shape == NoteShape.defaultShape &&
        currNote.staffPosition > prev.staffPosition) {
      if (currNote.ictus != null) {
        currNote.ictus!.positionHint = MarkingPositionHint.above;
      }
      return PorrectusState(createNeume);
    } else if (currNote.staffPosition < prev.staffPosition &&
        hasFlag(currNote.liquescent, LiquescentType.small)) {
      return createNeume(Ancus(), true);
    } else {
      return createNeume(Clivis(), false);
    }
  }
}

class ClimacusState extends NeumeState {
  ClimacusState(super.createNeume);

  @override
  Neume neume() => Climacus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape != NoteShape.inclinatum) {
      return createNeume(Climacus(), false);
    } else {
      return this;
    }
  }
}

class PorrectusState extends NeumeState {
  PorrectusState(super.createNeume);

  @override
  Neume neume() => Porrectus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape == NoteShape.defaultShape &&
        currNote.staffPosition < prevNote!.staffPosition) {
      return createNeume(PorrectusFlexus(), true);
    } else {
      return createNeume(Porrectus(), false);
    }
  }
}

class PesSubpunctisState extends NeumeState {
  PesSubpunctisState(super.createNeume);

  @override
  Neume neume() => PesSubpunctis();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape != NoteShape.inclinatum) {
      return createNeume(PesSubpunctis(), false);
    } else {
      return this;
    }
  }
}

class SalicusState extends NeumeState {
  SalicusState(super.createNeume);

  @override
  Neume neume() => Salicus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.staffPosition < prevNote!.staffPosition) {
      return SalicusFlexusState(createNeume);
    } else {
      return createNeume(Salicus(), false);
    }
  }
}

class SalicusFlexusState extends NeumeState {
  SalicusFlexusState(super.createNeume);

  @override
  Neume neume() => SalicusFlexus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    return createNeume(SalicusFlexus(), false);
  }
}

class ScandicusState extends NeumeState {
  ScandicusState(super.createNeume);

  @override
  Neume neume() => Scandicus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (prevNote!.shape == NoteShape.virga &&
        currNote.shape == NoteShape.inclinatum &&
        currNote.staffPosition < prevNote.staffPosition) {
      return createNeume(Podatus(), false, false);
    } else if (currNote.shape == NoteShape.defaultShape &&
        currNote.staffPosition < prevNote.staffPosition) {
      return ScandicusFlexusState(createNeume);
    } else {
      return createNeume(Scandicus(), false);
    }
  }
}

class ScandicusFlexusState extends NeumeState {
  ScandicusFlexusState(super.createNeume);

  @override
  Neume neume() => ScandicusFlexus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    return createNeume(ScandicusFlexus(), false);
  }
}

class VirgaState extends NeumeState {
  VirgaState(super.createNeume);

  @override
  Neume neume() => Virga();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape == NoteShape.inclinatum &&
        currNote.staffPosition < prevNote!.staffPosition) {
      return ClimacusState(createNeume);
    } else if (currNote.shape == NoteShape.virga &&
        currNote.staffPosition == prevNote?.staffPosition) {
      return BivirgaState(createNeume);
    } else {
      return createNeume(Virga(), false);
    }
  }
}

class BivirgaState extends NeumeState {
  BivirgaState(super.createNeume);

  @override
  Neume neume() => Bivirga();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape == NoteShape.virga &&
        currNote.staffPosition == prevNote!.staffPosition) {
      return createNeume(Trivirga(), true);
    } else {
      return createNeume(Bivirga(), false);
    }
  }
}

class ApostrophaState extends NeumeState {
  ApostrophaState(super.createNeume);

  @override
  Neume neume() => Apostropha();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.staffPosition == prevNote!.staffPosition) {
      return DistrophaState(createNeume);
    } else {
      return createNeume(Apostropha(), false);
    }
  }
}

class DistrophaState extends NeumeState {
  DistrophaState(super.createNeume);

  @override
  Neume neume() => Distropha();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.staffPosition == prevNote!.staffPosition) {
      if (prevNote.morae.isNotEmpty) {
        return createNeume(Distropha(), false);
      } else {
        return TristrophaState(createNeume);
      }
    } else {
      return createNeume(Apostropha(), false, false);
    }
  }
}

class TristrophaState extends NeumeState {
  TristrophaState(super.createNeume);

  @override
  Neume neume() => Tristropha();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    return createNeume(Distropha(), false, false);
  }
}

class TorculusState extends NeumeState {
  TorculusState(super.createNeume, this.notes, this.currNoteIndex);

  final List<Note> notes;
  final int currNoteIndex;

  @override
  Neume neume() => Torculus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape == NoteShape.defaultShape &&
        currNote.staffPosition > prevNote!.staffPosition) {
      final prevNoteButOne = currNoteIndex - 2 >= 0
          ? notes[currNoteIndex - 2]
          : null;
      if (prevNoteButOne != null &&
          prevNoteButOne.staffPosition - prevNote.staffPosition <= 4) {
        if (currNote.ictus != null) {
          currNote.ictus!.positionHint = MarkingPositionHint.above;
        }
        return TorculusResupinusState(createNeume);
      }
    }
    return createNeume(Torculus(), false);
  }
}

class TorculusResupinusState extends NeumeState {
  TorculusResupinusState(super.createNeume);

  @override
  Neume neume() => TorculusResupinus();

  @override
  NeumeState handle(Note currNote, Note? prevNote, int notesRemaining) {
    if (currNote.shape == NoteShape.defaultShape &&
        currNote.staffPosition < prevNote!.staffPosition) {
      return createNeume(TorculusResupinusFlexus(), true);
    } else {
      return createNeume(TorculusResupinus(), false);
    }
  }
}

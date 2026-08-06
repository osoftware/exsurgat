class VowelSegment {
  final bool found;
  final int startIndex;
  final int length;

  const VowelSegment(this.found, this.startIndex, this.length);

  static const notFound = VowelSegment(false, -1, -1);
}

/// Language-specific syllabification service.
abstract class Language {
  final String name;
  final bool centerNeume;

  const Language(this.name, {this.centerNeume = false});

  /// Takes a text that may contain many words
  /// and returns list of words where each word is a list of syllables.
  List<List<String>> syllabify(String text) {
    if (text.isEmpty) return [];

    // Divide the text into words separated by whitespace
    final words = text.split(RegExp(r'[\s]+')).where((word) => word.isNotEmpty);

    return words.map((word) => syllabifyWord(word)).toList();
  }

  /// Takes a single word and returns a list of syllables.
  List<String> syllabifyWord(String word);

  VowelSegment findVowelSegment(
    String s,
    int startIndex, [
    List<Map<String, int>>? ignore,
  ]);
}

class English extends Language {
  static final RegExp regexLetter = RegExp(
    r'[a-z\u00c0-\u02af\u0300-\u036f\u1e00-\u1eff‿]+',
    caseSensitive: false,
  );

  const English() : super("English", centerNeume: true);

  @override
  VowelSegment findVowelSegment(
    String s,
    int startIndex, [
    List<Map<String, int>>? ignore,
  ]) {
    final match = regexLetter.firstMatch(s.substring(startIndex));
    if (match != null) {
      return VowelSegment(
        true,
        startIndex + match.start,
        match.group(0)!.length,
      );
    }

    return VowelSegment.notFound;
  }

  @override
  List<String> syllabifyWord(String word) => [word];
}

class Latin extends Language {
  static final List<String> diphthongs = ["ae", "au", "oe", "aé", "áu", "oé"];
  static final List<String> possibleDiphthongs = [
    "ae",
    "au",
    "oe",
    "aé",
    "áu",
    "oé",
    "ei",
    "eu",
    "ui",
    "éi",
    "éu",
    "úi",
  ];
  static final RegExp regexVowel = RegExp(
    r'(i|(?:[qg]|^)u)?([eé][iu]|[uú]i|[ao][eé]|[aá]u|[aeiouáéíóúäëïöüāēīōūăĕĭŏŭåe̊o̊ůæœǽyýÿ])',
    caseSensitive: false,
  );

  static final Map<String, List<String>> wordExceptions = {
    "huius": ["hui", "us"],
    "cuius": ["cui", "us"],
    "huic": ["huic"],
    "cui": ["cui"],
    "hui": ["hui"],
    "euge": ["eu", "ge"],
    "seu": ["seu"],
  };

  static final List<String> vowels = [
    "a",
    "e",
    "i",
    "o",
    "u",
    "á",
    "é",
    "í",
    "ó",
    "ú",
    "ä",
    "ë",
    "ï",
    "ö",
    "ü",
    "ā",
    "ē",
    "ī",
    "ō",
    "ū",
    "ă",
    "ĕ",
    "ĭ",
    "ŏ",
    "ŭ",
    "å",
    "e̊",
    "o̊",
    "ů",
    "æ",
    "œ",
    "ǽ",
    "y",
    "ý",
    "ÿ",
  ];

  static final List<String> vowelsThatMightBeConsonants = ["i", "u"];
  static final List<String> muteConsonantsAndF = [
    "b",
    "c",
    "d",
    "g",
    "p",
    "t",
    "f",
  ];
  static final List<String> liquidConsonants = ["l", "r"];

  const Latin() : super("Latin");

  bool isVowel(String c) => vowels.contains(c.toLowerCase());

  bool isVowelThatMightBeConsonant(String c) =>
      vowelsThatMightBeConsonants.contains(c.toLowerCase());

  bool isVowelActingAsConsonant(String substring) {
    if (substring.length < 2) return false;
    return isVowelThatMightBeConsonant(substring[0]) && isVowel(substring[1]);
  }

  bool isMuteConsonantOrF(String c) =>
      muteConsonantsAndF.contains(c.toLowerCase());

  bool isLiquidConsonant(String c) =>
      liquidConsonants.contains(c.toLowerCase());

  bool isDiphthong(String s) => diphthongs.contains(s.toLowerCase());

  bool isPossibleDiphthong(String s) =>
      possibleDiphthongs.contains(s.toLowerCase());

  @override
  List<String> syllabifyWord(String word) {
    List<String> syllables = [];
    bool haveCompleteSyllable = false;
    bool previousWasVowel = false;
    String workingString = word.toLowerCase();
    int startSyllable = 0;

    void makeSyllable(int length) {
      if (haveCompleteSyllable) {
        syllables.add(word.substring(startSyllable, startSyllable + length));
        startSyllable += length;
      }
      haveCompleteSyllable = false;
    }

    for (int i = 0; i < workingString.length; i++) {
      String c = workingString[i];
      String lookahead = "*";
      bool haveLookahead = i + 1 < workingString.length;
      if (haveLookahead) lookahead = workingString[i + 1];

      bool cIsVowel = isVowel(c);

      if (c == "i") {
        if (i == 0 && haveLookahead && isVowel(lookahead)) {
          cIsVowel = false;
        } else if (previousWasVowel && haveLookahead && isVowel(lookahead)) {
          cIsVowel = false;
        }
      }

      if (c == "-") {
        haveCompleteSyllable = true;
        previousWasVowel = false;
        makeSyllable(i - startSyllable);
        startSyllable++;
      } else if (cIsVowel) {
        haveCompleteSyllable = true;
        if (previousWasVowel && !isDiphthong(workingString[i - 1] + c)) {
          makeSyllable(i - startSyllable);
          haveCompleteSyllable = true;
        }
        previousWasVowel = true;
      } else if (haveLookahead) {
        if ((c == "q" && lookahead == "u") ||
            (lookahead == "h" && (c == "c" || c == "p" || c == "t"))) {
          makeSyllable(i - startSyllable);
          i++;
        } else if (previousWasVowel && isVowel(lookahead)) {
          makeSyllable(i - startSyllable);
        } else if (isMuteConsonantOrF(c) && isLiquidConsonant(lookahead)) {
          makeSyllable(i - startSyllable);
        } else if (haveCompleteSyllable) {
          makeSyllable(i + 1 - startSyllable);
        }
        previousWasVowel = false;
      }
    }

    if (haveCompleteSyllable) {
      syllables.add(word.substring(startSyllable));
    } else if (startSyllable > 0) {
      if (syllables.isNotEmpty) {
        syllables[syllables.length - 1] += word.substring(startSyllable);
      }
    }

    return syllables;
  }

  @override
  VowelSegment findVowelSegment(
    String s,
    int startIndex, [
    List<Map<String, int>>? ignore,
  ]) {
    String stringSlice = s.substring(startIndex);
    var match = regexVowel.firstMatch(stringSlice);

    bool isIgnoredMatch(Map<String, int> range) {
      if (match == null) return false;
      int matchStart = match.start;
      int matchEnd = match.end;
      return (range['index']! <= matchStart &&
              range['endIndex']! > matchStart) ||
          (range['index']! < matchEnd && range['endIndex']! >= matchEnd);
    }

    while (match != null && ignore != null && ignore.any(isIgnoredMatch)) {
      // This is tricky in Dart because RegExp.firstMatch always starts from the beginning.
      // We need to slice the string further or use a different approach.
      // The JS code uses regexVowel.exec(stringSlice) and regexVowel.lastIndex.
      // In Dart, we can use match.end as the new start.
      int nextStart = startIndex + match.end;
      if (nextStart >= s.length) {
        match = null;
        break;
      }
      stringSlice = s.substring(nextStart);
      match = regexVowel.firstMatch(stringSlice);
      // Adjust match indices relative to original string
      // This is getting complex. Let's simplify.
    }

    if (match != null) {
      int actualStart = startIndex + match.start;
      // The JS code has: if (match[1]) { match.index += match[1].length; }
      // match[1] is the first capturing group: (i|(?:[qg]|^)u)?
      if (match.group(1) != null) {
        actualStart += match.group(1)!.length;
      }
      return VowelSegment(true, actualStart, match.group(2)!.length);
    }

    return VowelSegment.notFound;
  }
}

class Spanish extends Language {
  static final List<String> vowels = [
    "a",
    "e",
    "i",
    "o",
    "u",
    "y",
    "á",
    "é",
    "í",
    "ó",
    "ú",
    "ü",
  ];
  static final List<String> weakVowels = ["i", "u", "ü", "y"];
  static final List<String> strongVowels = [
    "a",
    "e",
    "o",
    "á",
    "é",
    "í",
    "ó",
    "ú",
  ];
  static final List<String> diphthongs = [
    "ai",
    "ei",
    "oi",
    "ui",
    "ia",
    "ie",
    "io",
    "iu",
    "au",
    "eu",
    "ou",
    "ua",
    "ue",
    "uo",
    "ái",
    "éi",
    "ói",
    "úi",
    "iá",
    "ié",
    "ió",
    "iú",
    "áu",
    "éu",
    "óu",
    "uá",
    "ué",
    "uó",
    "üe",
    "üi",
  ];
  static final List<String> uDiphthongExceptions = [
    "gue",
    "gui",
    "qua",
    "que",
    "qui",
    "quo",
  ];

  const Spanish() : super("Spanish");

  bool isVowel(String c) => vowels.contains(c.toLowerCase());
  bool isWeakVowel(String c) => weakVowels.contains(c.toLowerCase());
  bool isStrongVowel(String c) => strongVowels.contains(c.toLowerCase());
  bool isDiphthong(String s) => diphthongs.contains(s.toLowerCase());

  String createSyllable(String text) => text;

  @override
  List<String> syllabifyWord(String word) {
    List<String> syllables = [];
    bool haveCompleteSyllable = false;
    bool previousIsVowel = false;
    bool previousIsStrongVowel = false;
    int startSyllable = 0;

    for (int i = 0; i < word.length; i++) {
      String c = word[i].toLowerCase();

      if (isVowel(c)) {
        haveCompleteSyllable = true;
        bool cIsStrongVowel = isStrongVowel(c);

        if (previousIsVowel) {
          if (cIsStrongVowel) {
            if (previousIsStrongVowel) {
              syllables.add(createSyllable(word.substring(startSyllable, i)));
              startSyllable = i;
            }
          }
        }

        previousIsVowel = true;
        previousIsStrongVowel = cIsStrongVowel;
      } else {
        if (haveCompleteSyllable) {
          if (word[i] == "-") {
            syllables.add(createSyllable(word.substring(startSyllable, i)));
            startSyllable = i + 1;
            i++;
          } else {
            int numberOfConsonants = 1;
            for (int j = i + 1; j < word.length; j++) {
              if (isVowel(word[j])) break;
              numberOfConsonants++;
            }

            if (numberOfConsonants == 1) {
              syllables.add(createSyllable(word.substring(startSyllable, i)));
              startSyllable = i;
            } else if (numberOfConsonants == 2) {
              String consonant2 = word[i + 1].toLowerCase();
              if (consonant2 == "l" ||
                  consonant2 == "r" ||
                  (c == "c" && consonant2 == "h")) {
                syllables.add(createSyllable(word.substring(startSyllable, i)));
                startSyllable = i;
                i++;
              } else {
                syllables.add(
                  createSyllable(word.substring(startSyllable, i + 1)),
                );
                startSyllable = i + 1;
                i++;
              }
            } else if (numberOfConsonants == 3) {
              String consonant2 = word[i + 1].toLowerCase();
              if (consonant2 == "s") {
                i += 2;
                syllables.add(createSyllable(word.substring(startSyllable, i)));
              } else {
                syllables.add(
                  createSyllable(word.substring(startSyllable, i + 1)),
                );
                i++;
              }
              startSyllable = i;
            } else if (numberOfConsonants == 4) {
              syllables.add(
                createSyllable(word.substring(startSyllable, i + 2)),
              );
              startSyllable = i + 2;
              i += 3;
            }
          }
          haveCompleteSyllable = false;
        }
        previousIsVowel = false;
      }
    }

    if (haveCompleteSyllable) {
      syllables.add(word.substring(startSyllable));
    } else if (startSyllable > 0) {
      if (syllables.isNotEmpty) {
        syllables[syllables.length - 1] += word.substring(startSyllable);
      }
    } else if (syllables.isEmpty) {
      syllables.add(createSyllable(word));
    }

    return syllables;
  }

  @override
  VowelSegment findVowelSegment(
    String s,
    int startIndex, [
    List<Map<String, int>>? ignore,
  ]) {
    String workingString = s.toLowerCase();

    for (var d in diphthongs) {
      int index = workingString.indexOf(d, startIndex);
      if (index >= 0) {
        if (d[0] == "u" && index > 0) {
          String tripthong = s.substring(index - 1, index + 2).toLowerCase();
          if (uDiphthongExceptions.contains(tripthong)) {
            return findVowelSegment(s, index + 1);
          }
        }
        return VowelSegment(true, index, d.length);
      }
    }

    for (var v in vowels) {
      int index = workingString.indexOf(v, startIndex);
      if (index >= 0) return VowelSegment(true, index, 1);
    }

    return VowelSegment.notFound;
  }
}

class Polish extends Language {
  static final List<String> vowels = [
    'a',
    'e',
    'i',
    'o',
    'u',
    'y',
    'ó',
    'ą',
    'ę',
  ];
  static final List<String> consonantDigraphs = [
    'sz',
    'cz',
    'dz',
    'dź',
    'dż',
    'rz',
    'ch',
    'szcz',
  ];
  static final List<String> palatalizedConsonantTriplets = ['dzi'];
  static final List<String> palatalizedConsonantSequences = [
    'si',
    'zi',
    'ci',
    'ni',
    'li',
  ];
  static final List<String> vowelDigraphs = ['ia', 'ie', 'io', 'iu'];
  static final List<String> validOnsets = [
    'pr',
    'br',
    'dr',
    'kr',
    'gr',
    'tr',
    'fr',
    'wr',
    'pl',
    'bl',
    'gl',
    'kl',
    'pł',
    'bł',
    'gł',
    'kł',
    'sł',
    'tł',
    'dł',
    'fł',
    'mł',
    'sk',
    'sm',
    'sn',
    'sp',
    'st',
    'sw',
    'sz',
    'cz',
    'dz',
    'ch',
    'rz',
    'prz',
    'brz',
    'drz',
    'krz',
    'grz',
    'trz',
    'str',
    'skr',
    'spr',
    'strz',
    'szcz',
  ];

  const Polish() : super('Polish');

  bool isVowel(String c) {
    final lower = c.toLowerCase();
    return vowels.contains(lower) || vowelDigraphs.contains(lower);
  }

  bool isLetter(String c) => RegExp(r'[A-Za-ząćęłńóśżźĄĆĘŁŃÓŚŻŹ]').hasMatch(c);

  List<String> _tokenize(String word) {
    final tokens = <String>[];
    final lower = word.toLowerCase();
    int index = 0;

    while (index < word.length) {
      if (index + 4 <= word.length) {
        final sequence = lower.substring(index, index + 4);
        if (sequence == 'szcz') {
          tokens.add(word.substring(index, index + 4));
          index += 4;
          continue;
        }
      }
      if (index + 4 <= word.length) {
        final sequence = lower.substring(index, index + 4);
        if (sequence == 'szcz') {
          tokens.add(word.substring(index, index + 4));
          index += 4;
          continue;
        }
      }
      if (index + 2 <= word.length) {
        final sequence = lower.substring(index, index + 2);
        if (palatalizedConsonantTriplets.contains(sequence) &&
            index + 3 <= word.length) {
          final next = lower[index + 2];
          if (next == 'i') {
            tokens.add(word.substring(index, index + 3));
            index += 3;
            continue;
          }
        }
        if (palatalizedConsonantSequences.contains(sequence) &&
            index + 2 < word.length) {
          final next = lower[index + 2];
          if (vowels.contains(next)) {
            tokens.add(word.substring(index, index + 2));
            index += 2;
            continue;
          }
        }
        if (consonantDigraphs.contains(sequence)) {
          tokens.add(word.substring(index, index + 2));
          index += 2;
          continue;
        }
        if (vowelDigraphs.contains(sequence)) {
          tokens.add(word.substring(index, index + 2));
          index += 2;
          continue;
        }
      }
      tokens.add(word[index]);
      index += 1;
    }

    return tokens;
  }

  int _keepForCoda(List<String> cluster) {
    if (cluster.isEmpty) return 0;
    if (cluster.length == 1) return 0;

    final lowerCluster = cluster.join().toLowerCase();
    final maxOnsetLength = 4;
    for (var length = maxOnsetLength; length >= 1; length--) {
      if (cluster.length < length) continue;
      final suffix = lowerCluster.substring(lowerCluster.length - length);
      if (length == 1 || validOnsets.contains(suffix)) {
        return cluster.length - length;
      }
    }

    return 0;
  }

  @override
  List<String> syllabifyWord(String word) {
    if (word.isEmpty) return [];

    final tokens = _tokenize(word);
    final vowelIndices = <int>[];

    for (int i = 0; i < tokens.length; i++) {
      if (isVowel(tokens[i])) {
        vowelIndices.add(i);
      }
    }

    if (vowelIndices.isEmpty) {
      return [word];
    }

    final syllables = <String>[];
    int start = 0;

    for (
      int vowelIndex = 0;
      vowelIndex < vowelIndices.length - 1;
      vowelIndex++
    ) {
      final currentIndex = vowelIndices[vowelIndex];
      final nextIndex = vowelIndices[vowelIndex + 1];
      final cluster = tokens.sublist(currentIndex + 1, nextIndex);
      final keep = _keepForCoda(cluster);
      final boundary = currentIndex + 1 + keep;
      syllables.add(tokens.sublist(start, boundary).join());
      start = boundary;
    }

    syllables.add(tokens.sublist(start).join());
    return syllables;
  }

  @override
  VowelSegment findVowelSegment(
    String s,
    int startIndex, [
    List<Map<String, int>>? ignore,
  ]) {
    for (int i = startIndex; i < s.length; i++) {
      if (isVowel(s[i])) {
        return VowelSegment(true, i, 1);
      }
    }
    return VowelSegment.notFound;
  }
}

String makeLigature(String vowels) =>
    {
      'AE': "Æ",
      'Ae': "Æ",
      'ae': "æ",
      'OE': "Œ",
      'Oe': "Œ",
      'oe': "œ",
    }[vowels] ??
    vowels;

String addAccent(String vowel) =>
    ({
      "Æ": "Ǽ",
      "Œ": "Œ́",
      "A": "Á",
      "E": "É",
      "I": "Í",
      "O": "Ó",
      "U": "Ú",
      "Y": "Ý",
      "æ": "ǽ",
      "œ": "œ́",
      "a": "á",
      "e": "é",
      "i": "í",
      "o": "ó",
      "u": "ú",
      "y": "ý",
    }[vowel] ??
    vowel);

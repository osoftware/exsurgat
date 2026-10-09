## 0.2.3

* BUGFIX: Fixed stale sourceIndex of syllables after source update.

## 0.2.2

* Insertion preview for any notation element, including note attachments
  (accents, ictus, horizontal episemata, morae)
* Pitch normalisation: `Pitch` accepts out-of-range steps and octaves
* Gabc generation for accidentals, do-flat clefs and horizontal episemata;
  `Mora` and `HorizontalEpisema` track their source position
* `GabcHeader` improvements: entry assignment, `remove()` clearing all key
  variants, `setEntry()` with array support; empty value removes the entry
* `initial-style: 0` header now disables the drop cap
* Parsing, layout and hit testing of choral signs and note-attached
  above-line text
* Export `HorizontalEpisema`, `Accent` and `Ictus` from `internals.dart`
* BUGFIX: Fixed alignment of text with markup
* BUGFIX: Fixed hit testing of dividers and notes
* BUGFIX: Fixed annotation removal and annotation hit-testing
* BUGFIX: Fixed Translation lines not affecting ChantLine total height
* BUGFIX: Fixed sourceIndex for multi-line lyrics
* BUGFIX: Preserved selection of startingClef after reparse
* BUGFIX: Fixed punctum cavum gabc generation
* BUGFIX: Fixed dropCap caching

## 0.2.1

* BUGFIX: Fixed sourceIndex of syllables containing spaces. 

## 0.2.0

* Paginated score rendering: `ChantScore.paginate()` splits the score into
  pages, and `ChantScoreBody`/`ChantScoreView` arrange them in a row, column,
  facing pairs, or a single page via `PageArrangement`
* Page layout (page size, margins) and theme read from GABC header
  (`page-width`, `page-height`, `margin-*`) via `ChantDocumentLayout`

## 0.1.0

* Compile Gregorian chant from GABC source
* Display the sheet as a scrollable or non-scrollable Flutter widget
* Export to SVG or PNG
* Customize layout and colors

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

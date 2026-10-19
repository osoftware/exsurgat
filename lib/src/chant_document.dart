import 'package:flutter/foundation.dart';

import 'chant_context.dart';
import 'chant_document_layout.dart';
import 'chant_score.dart';
import 'chant_theme.dart';
import 'gabc.dart';

/// A document containing a chant score, along with layout and theme settings.
class ChantDocument extends ChangeNotifier {
  ChantDocument._({
    required String source,
    required GabcHeader header,
    required ChantDocumentLayout layout,
    required ChantTheme theme,
    required ChantContext ctxt,
    required ChantScore score,
  }) : _source = source,
       _score = score,
       _header = header,
       _theme = theme,
       _layout = layout,
       _ctxt = ctxt {
    score.addListener(_handleScoreChanged);
  }

  String _source;

  /// The raw GABC source from which other properties have been derived.
  String get source => _source;

  ChantContext _ctxt;

  /// Chant context maintaining internal state necessary for layout rendering.
  ChantContext get ctxt => _ctxt;
  set ctxt(ChantContext value) {
    if (value == _ctxt) return;
    _ctxt = value;
    notifyListeners();
  }

  /// The full header of this document.
  GabcHeader _header;

  /// The full header of this document.
  GabcHeader get header => _header;
  set header(GabcHeader value) {
    if (value == _header) return;
    _header = value;
    notifyListeners();
  }

  ChantDocumentLayout _layout = ChantDocumentLayout();

  /// The layout settings for this document.
  ChantDocumentLayout get layout => _layout;
  set layout(ChantDocumentLayout value) {
    if (value == _layout) return;
    _layout = value;
    _score.needsLayout = true;
    notifyListeners();
  }

  ChantTheme _theme = ChantTheme();

  /// The theme settings for this document.
  ChantTheme get theme => _theme;
  set theme(ChantTheme value) {
    if (value == _theme) return;
    _theme = value;
    _ctxt.theme = value;
    score.performLayout(ctxt, force: true);
    score.needsLayout = true;
    notifyListeners();
  }

  ChantScore _score;

  /// The score contained in this document.
  ChantScore get score => _score;
  set score(ChantScore value) {
    if (value == _score) return;
    _score.removeListener(_handleScoreChanged);
    _score = value;
    value.addListener(_handleScoreChanged);
    notifyListeners();
  }

  void _handleScoreChanged() => notifyListeners();

  @override
  void dispose() {
    score.removeListener(_handleScoreChanged);
    super.dispose();
  }

  /// Copies the layout settings from [from] to [to].
  void copyLayout(ChantDocument to, ChantDocumentLayout from) {
    to.layout = from.clone();
  }

  /// Creates the document from a GABC source.
  factory ChantDocument.fromSource(String source, [ChantContext? ctxt]) {
    ctxt = ctxt ?? ChantContext();

    final header = GabcHeader.fromSource(source);
    return ChantDocument._(
      source: source,
      ctxt: ctxt,
      header: header,
      layout: ChantDocumentLayout.fromGabcHeader(GabcHeader.fromSource(source)),
      theme: ChantTheme.fromGabcHeader(GabcHeader.fromSource(source)),
      score: ChantScore(
        ctxt: ctxt,
        header: header,
        words: Gabc.fromSource(ctxt, source),
        useDropCap: !(header['initial-style'] == "0"),
      ),
    );
  }

  /// Updates this document and notifies listeners.
  void updateSource(String source) {
    _source = source;
    _header = GabcHeader.fromSource(source);

    Gabc.updateAstFromSource(_ctxt, _score.words, source);
    _score.useDropCap = !(_header['initial-style'] == "0");
    _score.updateNotations(ctxt);
    _score.updateHeader(ctxt, _header);

    final newTheme = ChantTheme.fromGabcHeader(_header);
    final themeChanged = newTheme != _theme;
    _theme = newTheme;
    _ctxt.theme = _theme;
    if (themeChanged) {
      // Text metrics were measured with the old theme; force a full notation
      // relayout. needsLayout stays set so chant lines are rebuilt too.
      _score.performLayout(ctxt, force: true);
      _score.needsLayout = true;
    }

    final newLayout = ChantDocumentLayout.fromGabcHeader(_header);
    final layoutChanged = newLayout != _layout;
    _layout = newLayout;
    if (layoutChanged) {
      // Page geometry changed; mark the score so the next layout pass rebuilds
      // the chant lines at the new content width/margins.
      _score.needsLayout = true;
    }
  }

  /// Serializes the document to gabc source.
  @override
  String toString() {
    layout.updateHeader(header);
    theme.updateHeader(header);
    final body = score.words.map((w) => w.source).join();
    return '$header$body';
  }
}

import 'package:flutter/foundation.dart';

import 'chant_context.dart';
import 'chant_score.dart';
import 'chant_theme.dart';
import 'core.dart';
import 'gabc.dart';

/// The layout settings for a [ChantDocument].
class ChantDocumentLayout {
  static const kDefaultPageWidth = Scalar(8.5, Unit.inches);
  static const kDefaultPageHeight = Scalar(11, Unit.inches);
  static const kDefaultMarginLeft = Scalar(0);
  static const kDefaultMarginTop = Scalar(0);
  static const kDefaultMarginRight = Scalar(0);
  static const kDefaultMarginBottom = Scalar(0);

  const ChantDocumentLayout({
    this.pageWidth = kDefaultPageWidth,
    this.pageHeight = kDefaultPageHeight,
    this.marginLeft = kDefaultMarginLeft,
    this.marginTop = kDefaultMarginTop,
    this.marginRight = kDefaultMarginRight,
    this.marginBottom = kDefaultMarginBottom,
  });

  /// The width of the page.
  final Scalar pageWidth;

  /// The height of the page.
  final Scalar pageHeight;

  /// The left margin of the page.
  final Scalar marginLeft;

  /// The top margin of the page.
  final Scalar marginTop;

  /// The right margin of the page.
  final Scalar marginRight;

  /// The bottom margin of the page.
  final Scalar marginBottom;

  /// Creates [ChantDocumentLayout] from [GabcHeader] values.
  factory ChantDocumentLayout.fromGabcHeader(GabcHeader header) =>
      ChantDocumentLayout(
        pageWidth: header.readScalar('page-width', kDefaultPageWidth),
        pageHeight: header.readScalar('page-height', kDefaultPageHeight),
        marginLeft: header.readScalar('margin-left', kDefaultMarginLeft),
        marginTop: header.readScalar('margin-top', kDefaultMarginTop),
        marginRight: header.readScalar('margin-right', kDefaultMarginRight),
        marginBottom: header.readScalar('margin-bottom', kDefaultMarginBottom),
      );

  ChantDocumentLayout clone() => ChantDocumentLayout(
    pageWidth: pageWidth.clone(),
    pageHeight: pageHeight.clone(),
    marginLeft: marginLeft.clone(),
    marginTop: marginTop.clone(),
    marginRight: marginRight.clone(),
    marginBottom: marginBottom.clone(),
  );

  /// Updates [header] with this layout's values, compatible with [GabcHeader].
  ///
  /// Values that differ from the kDefault layout are set; values that equal
  /// the kDefault are removed from the header.
  void updateHeader(GabcHeader header) {
    header.put('page-width', '$pageWidth', '$kDefaultPageWidth');
    header.put('page-height', '$pageHeight', '$kDefaultPageHeight');
    header.put('margin-left', '$marginLeft', '$kDefaultMarginLeft');
    header.put('margin-top', '$marginTop', '$kDefaultMarginTop');
    header.put('margin-right', '$marginRight', '$kDefaultMarginRight');
    header.put('margin-bottom', '$marginBottom', '$kDefaultMarginBottom');
  }
}

/// A document containing a chant score, along with layout and theme settings.
class ChantDocument extends ChangeNotifier {
  ChantDocument({
    required GabcHeader header,
    required ChantDocumentLayout layout,
    required ChantTheme theme,
    required ChantContext ctxt,
    required ChantScore score,
  }) : _score = score,
       _header = header,
       _theme = theme,
       _layout = layout,
       _ctxt = ctxt {
    score.addListener(_handleScoreChanged);
  }

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
    notifyListeners();
  }

  ChantTheme _theme = ChantTheme();

  /// The theme settings for this document.
  ChantTheme get theme => _theme;
  set theme(ChantTheme value) {
    if (value == _theme) return;
    _theme = value;
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

  /// Unserializes the document from a JSON-compatible map.
  factory ChantDocument.fromSource(String source, [ChantContext? ctxt]) {
    ctxt = ctxt ?? ChantContext();

    final header = GabcHeader.fromSource(source);
    return ChantDocument(
      ctxt: ctxt,
      header: header,
      layout: ChantDocumentLayout.fromGabcHeader(GabcHeader.fromSource(source)),
      theme: ChantTheme.fromGabcHeader(GabcHeader.fromSource(source)),
      score: ChantScore(
        ctxt: ctxt,
        header: header,
        words: Gabc.fromSource(ctxt, source),
        useDropCap: !(header['initial-style'] == 0),
      ),
    );
  }
  void updateSource(String source) {
    _header = GabcHeader.fromSource(source);
    _layout = ChantDocumentLayout.fromGabcHeader(GabcHeader.fromSource(source));
    _theme = ChantTheme.fromGabcHeader(GabcHeader.fromSource(source));
    Gabc.updateAstFromSource(ctxt, score.words, source);
    score.useDropCap = !(_header['initial-style'] == 0);
    score.updateNotations(ctxt);
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

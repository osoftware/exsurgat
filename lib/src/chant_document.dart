import 'chant_context.dart';
import 'chant_score.dart';

/// The layout settings for a [ChantDocument].
class ChantDocumentLayout {
  ChantDocumentLayout({
    this.units = 'mm',
    this.defaultFontFamily = 'Crimson',
    this.defaultFontSize = 14,
    this.pageWidth = 8.5,
    this.pageHeight = 11,
    this.marginLeft = 0,
    this.marginTop = 0,
    this.marginRight = 0,
    this.marginBottom = 0,
  });

  /// The units used for the layout dimensions (e.g., "mm", "in").
  String units;

  /// The default font family for the document.
  String defaultFontFamily;

  /// The default font size for the document.
  double defaultFontSize;

  /// The width of the page.
  double pageWidth;

  /// The height of the page.
  double pageHeight;

  /// The left margin of the page.
  double marginLeft;

  /// The top margin of the page.
  double marginTop;

  /// The right margin of the page.
  double marginRight;

  /// The bottom margin of the page.
  double marginBottom;

  ChantDocumentLayout clone() => ChantDocumentLayout(
    units: units,
    defaultFontFamily: defaultFontFamily,
    defaultFontSize: defaultFontSize,
    pageWidth: pageWidth,
    pageHeight: pageHeight,
    marginLeft: marginLeft,
    marginTop: marginTop,
    marginRight: marginRight,
    marginBottom: marginBottom,
  );
}

/// A document containing one or more chant scores, along with layout settings.
class ChantDocument {
  ChantDocument() {
    final defaults = ChantDocumentLayout();
    copyLayout(this, defaults);
    scores = [];
  }

  /// The layout settings for this document.
  late ChantDocumentLayout layout;

  /// The scores contained in this document.
  late List<ChantScore> scores;

  /// Copies the layout settings from [from] to [to].
  void copyLayout(ChantDocument to, ChantDocumentLayout from) {
    to.layout = from.clone();
  }

  /// Unserializes the document from a JSON-compatible map.
  void unserializeFromJson(Map<String, dynamic> data, ChantContext ctxt) {
    final layoutData = data['layout'] as Map<String, dynamic>;
    final defaultFont =
        layoutData['default-font'] as Map<String, dynamic>? ?? {};
    final page = layoutData['page'] as Map<String, dynamic>? ?? {};

    layout = ChantDocumentLayout(
      units: layoutData['units'] as String? ?? 'mm',
      defaultFontFamily: defaultFont['font-family'] as String? ?? 'Crimson',
      defaultFontSize: (defaultFont['font-size'] as num?)?.toDouble() ?? 14,
      pageWidth: (page['width'] as num?)?.toDouble() ?? 8.5,
      pageHeight: (page['height'] as num?)?.toDouble() ?? 11,
      marginLeft: (page['margin-left'] as num?)?.toDouble() ?? 0,
      marginTop: (page['margin-top'] as num?)?.toDouble() ?? 0,
      marginRight: (page['margin-right'] as num?)?.toDouble() ?? 0,
      marginBottom: (page['margin-bottom'] as num?)?.toDouble() ?? 0,
    );

    scores = [];

    // read in the scores
    final scoresData = data['scores'] as List<dynamic>? ?? [];
    for (var i = 0; i < scoresData.length; i++) {
      final score = ChantScore();
      score.unserializeFromJson(scoresData[i] as Map<String, dynamic>, ctxt);
      scores.add(score);
    }
  }

  /// Serializes the document to a JSON-compatible map.
  Map<String, dynamic> serializeToJson() {
    final data = <String, dynamic>{};

    data['layout'] = {
      'units': layout.units,
      'default-font': {
        'font-family': layout.defaultFontFamily,
        'font-size': layout.defaultFontSize,
      },
      'page': {
        'width': layout.pageWidth,
        'height': layout.pageHeight,
        'margin-left': layout.marginLeft,
        'margin-top': layout.marginTop,
        'margin-right': layout.marginRight,
        'margin-bottom': layout.marginBottom,
      },
    };

    data['scores'] = [];
    for (var i = 0; i < scores.length; i++) {
      (data['scores'] as List).add(scores[i].serializeToJson());
    }

    return data;
  }
}

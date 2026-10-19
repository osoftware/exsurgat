import 'chant_document.dart';
import 'core.dart';
import 'gabc.dart';

/// The layout settings for a [ChantDocument].
class ChantDocumentLayout {
  static const kDefaultPageWidth = Scalar(148, Unit.millimeters);
  static const kDefaultPageHeight = Scalar(210, Unit.millimeters);
  static const kDefaultMarginLeft = Scalar(10, Unit.millimeters);
  static const kDefaultMarginTop = Scalar(10, Unit.millimeters);
  static const kDefaultMarginRight = Scalar(10, Unit.millimeters);
  static const kDefaultMarginBottom = Scalar(10, Unit.millimeters);

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

  @override
  bool operator ==(Object other) =>
      other is ChantDocumentLayout &&
      pageWidth == other.pageWidth &&
      pageHeight == other.pageHeight &&
      marginLeft == other.marginLeft &&
      marginTop == other.marginTop &&
      marginRight == other.marginRight &&
      marginBottom == other.marginBottom;

  @override
  int get hashCode => Object.hash(
    pageWidth,
    pageHeight,
    marginLeft,
    marginTop,
    marginRight,
    marginBottom,
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

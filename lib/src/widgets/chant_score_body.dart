/// @docImport 'chant_score_view.dart';
/// @docImport '../elements/chant_layout_element.dart';
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../chant_context.dart';
import '../chant_document.dart';
import '../chant_score.dart';
import '../chant_theme.dart';
import '../core.dart';
import '../elements/annotations.dart';
import '../elements/notation/neumes/neume.dart';
import '../elements/text/drop_cap.dart';

/// How the pages of a paginated chant score are arranged.
enum PageArrangement {
  /// Single continuous score fitted to the parent width.
  /// Ignores [ChantDocumentLayout].
  auto,

  /// Unconstrained width: the score sizes to its content.
  /// Ignores [ChantDocumentLayout].
  slider,

  /// One page at a time.
  /// Use [ChantScoreBody.pageIndex] to select the displayed page.
  /// Page size and margins set by [ChantDocumentLayout] read from GABC header.
  single,

  /// All pages side by side in a horizontal row.
  /// Page size and margins set by [ChantDocumentLayout] read from GABC header.
  row,

  /// All pages stacked vertically in a column.
  /// Page size and margins set by [ChantDocumentLayout] read from GABC header.
  column,

  /// Pages in a grid of facing pairs (2 per row) like in a booklet.
  /// Page size and margins set by [ChantDocumentLayout] read from GABC header.
  facingPairs,
}

/// Chant score fitting the width constraints of the parent widget.
/// For scrollable widget see [ChantScoreView]
class ChantScoreBody extends LeafRenderObjectWidget {
  /// Creates a read-only chant score body parsed from [gabc].
  const ChantScoreBody({
    super.key,
    required this.gabc,
    this.useDropCap = true,
    this.theme,
    this.arrangement = PageArrangement.auto,
    this.pageIndex = 0,
    this.pageGap = 24,
    this.pageDecoration,
  }) : document = null,
       tool = null;

  /// Creates an editable chant score body backed by [document].
  const ChantScoreBody.editable({
    super.key,
    required this.document,
    this.theme,
    this.tool,
    this.arrangement = PageArrangement.auto,
    this.pageIndex = 0,
    this.pageGap = 24,
    this.pageDecoration,
  }) : gabc = '',
       useDropCap = null;

  /// The gabc source. Only used by the default constructor, which creates
  /// a [ChantDocument] from it.
  final String gabc;

  /// The document to edit. Only used by [ChantScoreBody.editable].
  final ChantDocument? document;

  /// Whether to display the initial.
  /// Overrides `initial-style` property in GABC header.
  final bool? useDropCap;

  final ChantTheme? theme;
  final Tool? tool;

  /// How pages are arranged. Defaults to [PageArrangement.auto], the legacy
  /// single-score behavior.
  final PageArrangement arrangement;

  /// The page displayed when [arrangement] is [PageArrangement.single].
  /// Ignored by other arrangements. Clamped to the valid page range.
  final int pageIndex;

  /// Gap between pages in paginated arrangements.
  final double pageGap;

  /// Decoration painted behind each page in paginated arrangements.
  final Decoration? pageDecoration;

  @override
  RenderBox createRenderObject(BuildContext context) {
    return RenderChantScore(
      gabc: gabc,
      document: document,
      useDropCap: useDropCap,
      theme: theme,
      tool: tool,
      arrangement: arrangement,
      pageIndex: pageIndex,
      pageGap: pageGap,
      pageDecoration: pageDecoration,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderChantScore renderObject) {
    super.updateRenderObject(context, renderObject);
    renderObject
      ..gabc = gabc
      ..document = document
      ..useDropCap = useDropCap
      ..theme = theme
      ..tool = tool
      ..arrangement = arrangement
      ..pageIndex = pageIndex
      ..pageGap = pageGap
      ..pageDecoration = pageDecoration;
  }
}

class RenderChantScore extends RenderBox implements MouseTrackerAnnotation {
  RenderChantScore({
    required String gabc,
    required ChantDocument? document,
    required bool? useDropCap,
    required ChantTheme? theme,
    required Tool? tool,
    required PageArrangement arrangement,
    required int pageIndex,
    required double pageGap,
    required Decoration? pageDecoration,
  }) : _gabc = gabc,
       _ownsDocument = document == null,
       _useDropCap = useDropCap,
       _tool = tool,
       _arrangement = arrangement,
       _pageIndex = pageIndex,
       _pageGap = pageGap,
       _pageDecoration = pageDecoration {
    if (theme != null) _chantContext.theme = theme;
    _document = document ?? ChantDocument.fromSource(gabc, _chantContext);
    // A provided theme overrides the document's theme.
    if (theme != null) _document.theme = theme;
    if (useDropCap != null) _document.score.useDropCap = useDropCap;
    _document.addListener(_handleDocumentChanged);
    _tool?._attachTo(this);
  }

  String _gabc;
  bool? _useDropCap;
  Tool? _tool;
  PageArrangement _arrangement;
  int _pageIndex;
  double _pageGap;
  Decoration? _pageDecoration;
  BoxPainter? _pagePainter;

  /// Whether the current arrangement paginates the score.
  bool get _isPaginated => switch (_arrangement) {
    .auto || .slider => false,
    _ => true,
  };

  /// Offsets of each page slot within this render object, valid after layout
  /// in paginated mode.
  final _pageOffsets = <Offset>[];

  /// Size of a single page slot, valid after layout in paginated mode.
  Size _pageSize = Size.zero;

  final ChantContext _chantContext = ChantContext();
  late ChantDocument _document;
  final bool _ownsDocument;
  bool _inLayout = false;
  bool _disposed = false;

  /// Width used for the last chant-line layout, to skip redundant relayouts.
  double? _lastLineWidth;

  String get gabc => _gabc;
  set gabc(String value) {
    if (value == _gabc) return;
    _gabc = value;
    // Only the default constructor parses gabc; an editable body is backed
    // by an externally provided document and ignores gabc updates.
    if (_ownsDocument) {
      document = ChantDocument.fromSource(value, _chantContext);
    }
  }

  /// The document whose score is rendered and edited.
  ChantDocument get document => _document;
  set document(ChantDocument? value) {
    if (value == null || value == _document) return;
    _document.removeListener(_handleDocumentChanged);
    _document = value;
    _document.addListener(_handleDocumentChanged);
    _lastLineWidth = null;
    _tool?.handleScoreUpdated();
    markNeedsLayout();
  }

  /// The score held by [document].
  ChantScore get score => _document.score;

  void _handleDocumentChanged() {
    if (_inLayout || _disposed) return;
    markNeedsLayout();
  }

  bool? get useDropCap => _useDropCap;
  set useDropCap(bool? value) {
    if (value == _useDropCap) return;
    _useDropCap = value;
    if (value != null) {
      score.useDropCap = value;
    } else {
      score.useDropCap = document.header['initial-style'] != 0;
    }
    markNeedsLayout();
  }

  Tool? get tool => _tool;
  set tool(Tool? value) {
    if (value == _tool) return;
    _tool = value;
    if (_disposed) return;
    _tool?._attachTo(this);
  }

  ChantTheme get theme => _chantContext.theme;
  set theme(ChantTheme? value) {
    if (value == null || value == _chantContext.theme) return;
    _chantContext.theme = value;
    _document.theme = value;
    score.needsLayout = true;
    markNeedsLayout();
  }

  PageArrangement get arrangement => _arrangement;
  set arrangement(PageArrangement value) {
    if (value == _arrangement) return;
    _arrangement = value;
    markNeedsLayout();
  }

  int get pageIndex => _pageIndex;
  set pageIndex(int value) {
    if (value == _pageIndex) return;
    _pageIndex = value;
    markNeedsLayout();
  }

  double get pageGap => _pageGap;
  set pageGap(double value) {
    if (value == _pageGap) return;
    _pageGap = value;
    markNeedsLayout();
  }

  Decoration? get pageDecoration => _pageDecoration;
  set pageDecoration(Decoration? value) {
    if (value == _pageDecoration) return;
    _pageDecoration = value;
    _pagePainter?.dispose();
    _pagePainter = value?.createBoxPainter(markNeedsPaint);
    markNeedsPaint();
  }

  /// The layout settings used in paginated mode, read from the document.
  ChantDocumentLayout get _layout => _document.layout;

  /// Content width available for chant lines: page width minus horizontal
  /// margins.
  double get _contentWidth =>
      _layout.pageWidth.deviceIndependent -
      _layout.marginLeft.deviceIndependent -
      _layout.marginRight.deviceIndependent;

  /// Content height available for chant lines: page height minus vertical
  /// margins.
  double get _contentHeight =>
      _layout.pageHeight.deviceIndependent -
      _layout.marginTop.deviceIndependent -
      _layout.marginBottom.deviceIndependent;

  /// Full page size including margins.
  Size get _fullPageSize => Size(
    _layout.pageWidth.deviceIndependent,
    _layout.pageHeight.deviceIndependent,
  );

  /// Offset of the score content within a page: the left and top margins.
  Offset get _contentOffset => Offset(
    _layout.marginLeft.deviceIndependent,
    _layout.marginTop.deviceIndependent,
  );

  /// Computes the slot offset of each page for the current arrangement.
  void _layoutPageSlots(int pageCount) {
    _pageOffsets.clear();
    final pageSize = _fullPageSize;
    _pageSize = pageSize;
    final gap = _pageGap;
    switch (_arrangement) {
      case .single:
        _pageOffsets.add(Offset.zero);
      case .row:
        for (var i = 0; i < pageCount; i++) {
          _pageOffsets.add(Offset(i * (pageSize.width + gap), 0));
        }
      case .column:
        for (var i = 0; i < pageCount; i++) {
          _pageOffsets.add(Offset(0, i * (pageSize.height + gap)));
        }
      case .facingPairs:
        // First page alone in the first row (right slot, like a book cover),
        // then pairs of pages. Pages in a pair are separated by a small
        // fixed gutter, while rows use the full page gap.
        const pairGutter = 4.0;
        for (var i = 0; i < pageCount; i++) {
          final row = i == 0 ? 0 : (i + 1) ~/ 2;
          final col = i == 0 ? 1 : (i + 1) % 2;
          _pageOffsets.add(
            Offset(
              col * (pageSize.width + pairGutter),
              row * (pageSize.height + gap),
            ),
          );
        }
      case .auto || .slider:
        break;
    }
  }

  /// Total size occupied by the page slots.
  Size get _paginatedSize {
    if (_pageOffsets.isEmpty) return _pageSize;
    final last = _pageOffsets.last;
    return Size(last.dx + _pageSize.width, last.dy + _pageSize.height);
  }

  /// Maps a local position to the page-local position for hit testing.
  /// Returns null when the position is outside all page slots.
  Offset? _positionToPageLocal(Offset position) {
    if (_pageOffsets.isEmpty) return null;
    final pageSize = _pageSize;
    for (var i = _pageOffsets.length - 1; i >= 0; i--) {
      final slot = _pageOffsets[i] & pageSize;
      if (slot.contains(position)) {
        return position - _pageOffsets[i];
      }
    }
    return null;
  }

  /// Index of the page a hit test is targeting, or null when not paginated.
  int? _hitTestPageIndex;

  /// Top shift of the page last hit tested (`-page.bounds.y`), persisted
  /// after the hit test so tools can convert pointer positions to
  /// score-relative coordinates during event handling.
  double _hitTestPageTop = 0;

  /// Converts a global pointer position to content-local coordinates matching
  /// element bounds (page slot offset and page margins removed). Returns null
  /// when the position is outside all page slots in paginated mode.
  Offset? pointerToContentLocal(Offset globalPosition) {
    final local = globalToLocal(globalPosition);
    if (!_isPaginated) return local;
    final pageLocal = _positionToPageLocal(local);
    if (pageLocal == null) return null;
    return pageLocal - _contentOffset;
  }

  /// Converts a global pointer position to score-relative coordinates
  /// (content-local plus the hit-test page's top shift), matching the
  /// score-relative bounds of chant lines. Returns null when the position is
  /// outside all page slots in paginated mode.
  Offset? pointerToScoreLocal(Offset globalPosition) {
    final contentLocal = pointerToContentLocal(globalPosition);
    if (contentLocal == null) return null;
    return Offset(contentLocal.dx, contentLocal.dy + _hitTestPageTop);
  }

  @override
  void dispose() {
    _disposed = true;
    _pagePainter?.dispose();
    _document.removeListener(_handleDocumentChanged);
    _document.score.removeListener(_handleDocumentChanged);
    super.dispose();
  }

  @override
  void performLayout() {
    _inLayout = true;
    final selection = score.selection;
    switch (_arrangement) {
      case .auto:
        _layoutScore(constraints.maxWidth);
        score.updateSelection(selection);
        _inLayout = false;
        _tool?.handleScoreUpdated();
        size = constraints.constrain(
          Size(score.bounds.width, score.bounds.height),
        );
      case .slider:
        _layoutScore(0);
        score.updateSelection(selection);
        _inLayout = false;
        _tool?.handleScoreUpdated();
        size = Size(score.bounds.width, score.bounds.height);
      case .single:
      case .row:
      case .column:
      case .facingPairs:
        _layoutScore(_contentWidth);
        score.paginate(_contentHeight);
        score.updateSelection(selection);
        _inLayout = false;
        _tool?.handleScoreUpdated();
        _layoutPageSlots(score.pages.length);
        size = constraints.constrain(_paginatedSize);
    }
  }

  /// Lays out the score's notations and chant lines at [width], skipping the
  /// expensive line rebuild when neither the score nor the width changed.
  /// This makes [performLayout] idempotent for paint-only changes such as
  /// selection or highlight updates.
  void _layoutScore(double width) {
    if (score.needsLayout || width != _lastLineWidth) {
      score.performLayout(_chantContext);
      score.layoutChantLines(_chantContext, width);
      _lastLineWidth = width;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _chantContext.attachCanvas(canvas);
    if (!_isPaginated) {
      score.draw(_chantContext);
      canvas.restore();
      return;
    }
    final pages = score.pages;
    final indices = switch (_arrangement) {
      .single => [_pageIndex.clamp(0, pages.length - 1)],
      _ => List.generate(pages.length, (i) => i),
    };
    for (final i in indices) {
      final slot = _pageOffsets[i];
      final decoration = _pageDecoration;
      if (decoration != null) {
        _pagePainter ??= decoration.createBoxPainter(markNeedsPaint);
        _pagePainter!.paint(canvas, slot, ImageConfiguration(size: _pageSize));
      }
      canvas.save();
      canvas.translate(
        slot.dx + _contentOffset.dx,
        slot.dy + _contentOffset.dy,
      );
      score.drawPage(_chantContext, pages[i]);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_isPaginated) {
      final pageLocal = _positionToPageLocal(position);
      if (pageLocal == null) return false;
      final contentLocal = pageLocal - _contentOffset;
      final pageIndex = switch (_arrangement) {
        .single => _pageIndex.clamp(0, score.pages.length - 1),
        _ => _pageOffsets.indexWhere(
          (slot) => (slot & _pageSize).contains(position),
        ),
      };
      _hitTestPageIndex = pageIndex;
      _hitTestPageTop = pageIndex >= 0 ? -score.pages[pageIndex].bounds.y : 0;
      final hit =
          tool?.hitTestElements(result, position: contentLocal) ??
          super.hitTest(result, position: contentLocal);
      _hitTestPageIndex = null;
      return hit;
    }
    return tool?.hitTestElements(result, position: position) ??
        super.hitTest(result, position: position);
  }

  @override
  MouseCursor get cursor => tool?.cursor ?? MouseCursor.defer;

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit => _tool?.handlePointerExit;

  @override
  bool get validForMouseTracker => _tool != null;
}

/// Provides pointer event handling for [ChantLayoutElement]
/// by redirecting it to [Tool.handleTargetEvent].
class ChantHitTestTarget<T> implements HitTestTarget {
  const ChantHitTestTarget(this.element);

  final T element;

  @override
  void handleEvent(PointerEvent event, covariant ChantHitTestEntry entry) {
    entry.renderObject.tool?.handleTargetEvent(event, this);
  }

  @override
  int get hashCode => element.hashCode;

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;
}

/// Data about a hit test target collected by [Tool.hitTestElements].
class ChantHitTestEntry<T> extends HitTestEntry<ChantHitTestTarget<T>> {
  ChantHitTestEntry(T target, this.renderObject)
    : super(ChantHitTestTarget(target));
  final RenderChantScore renderObject;
}

/// Base class for interactive editing tools.
/// The inheriting class needs to implement [handleTargetEvent]
/// and may override [hitTestElements].
abstract class Tool {
  late RenderChantScore _renderObject;
  void _attachTo(RenderChantScore renderObject) {
    _renderObject = renderObject;
    handleAttach();
  }

  /// Render object that this tool is attached to.
  RenderChantScore get renderObject => _renderObject;

  /// Score this tool is editing.
  ChantScore get score => renderObject.score;

  /// Chant context of the edited score.
  ChantContext get chantContext => _renderObject._chantContext;

  /// The page being hit tested, or null when not paginated. Set by
  /// [RenderChantScore.hitTest] before [hitTestElements] runs; tools should
  /// scope their hit testing to this page's lines.
  ChantScore? get hitTestPage {
    final index = renderObject._hitTestPageIndex;
    if (index == null || index < 0 || index >= score.pages.length) return null;
    return score.pages[index];
  }

  /// Override this getter to change the cursor display when this tool is active.
  MouseCursor get cursor => MouseCursor.defer;

  /// Determines a set of [ChantLayoutElement]s that are located at the given
  /// position or are relevant to it in the order from the innermost to
  /// the outermost.
  bool hitTestElements(BoxHitTestResult result, {required Offset position}) {
    final page = hitTestPage;
    // Pages share score-relative lines; the page's bounds.y cancels its first
    // line's offset, so shift the position down by -bounds.y to get
    // score-relative coordinates for hit testing.
    final pageTopShift = page == null ? 0.0 : -page.bounds.y;
    final globalPosition = Point(position.dx, position.dy + pageTopShift);
    final lines = page?.lines ?? score.lines;
    final hasFrontMatter = page == null || identical(page, score.pages.first);
    if (hasFrontMatter &&
        (page?.titles?.bounds.containsPoint(globalPosition) ??
            score.titles?.bounds.containsPoint(globalPosition) ??
            false)) {
      for (final t in (page?.titles ?? score.titles)!.elements) {
        if (t.boundsForHitTest.containsPoint(globalPosition)) {
          result.add(ChantHitTestEntry(t, renderObject));
          result.add(ChantHitTestEntry(score, renderObject));
          result.add(BoxHitTestEntry(renderObject, position));
          return true;
        }
      }
    }

    if (score.dropCap case DropCap(
      :final boundsForHitTest,
    ) when page == null || identical(page, score.pages.first)) {
      final dropCapBounds = boundsForHitTest.copyWith(
        y: boundsForHitTest.y + score.lines.first.bounds.y,
      );
      if (dropCapBounds.containsPoint(globalPosition)) {
        result.add(ChantHitTestEntry(score.dropCap!, renderObject));
        result.add(ChantHitTestEntry(score, renderObject));
        result.add(BoxHitTestEntry(renderObject, position));
        return true;
      }
      if (score.annotation case Annotations(:final annotations)) {
        for (final a in annotations) {
          final aBounds = a.boundsForHitTest.copyWith(
            y: a.boundsForHitTest.y + score.lines.first.boundsForHitTest.y,
            x: a.boundsForHitTest.x + score.annotation!.bounds.x,
          );
          if (aBounds.containsPoint(globalPosition)) {
            result.add(ChantHitTestEntry(a, renderObject));
            result.add(ChantHitTestEntry(score, renderObject));
            result.add(BoxHitTestEntry(renderObject, position));
            return true;
          }
        }
      }
    }

    for (final line in lines) {
      if (line.boundsForHitTest.containsPoint(globalPosition)) {
        final linePosition = Point(
          globalPosition.x - line.bounds.x,
          globalPosition.y - line.bounds.y,
        );
        if (line.startingClef?.boundsForHitTest.containsPoint(linePosition) ??
            false) {
          result.add(ChantHitTestEntry(line.startingClef!, renderObject));
        } else {
          for (final element in line.notations) {
            if (element.boundsForHitTest.containsPoint(linePosition)) {
              if (element case Neume(:final notes)) {
                for (final note in notes.reversed) {
                  final noteBounds = note.bounds.copyWith(
                    x: element.bounds.x + note.bounds.x,
                  );
                  if (noteBounds.containsPoint(linePosition)) {
                    result.add(ChantHitTestEntry(note, renderObject));
                    break;
                  }
                }
              }

              result.add(ChantHitTestEntry(element, renderObject));
              break;
            }
            final neumePosition = Point(
              linePosition.x - element.bounds.x,
              linePosition.y,
            );
            for (final text in [
              ...element.lyrics,
              ...element.translationText,
              ...element.alText,
            ]) {
              if (text.boundsForHitTest.containsPoint(neumePosition)) {
                result.add(ChantHitTestEntry(text, renderObject));
                result.add(ChantHitTestEntry(element, renderObject));
                break;
              }
            }
          }
        }

        result.add(ChantHitTestEntry(line, renderObject));
      }
    }

    if (renderObject.size.contains(position)) {
      result.add(ChantHitTestEntry(score, renderObject));
      result.add(BoxHitTestEntry(renderObject, position));
      return true;
    }

    return false;
  }

  /// Override this method to handle pointer events.
  ///
  /// This method is is called for each [ChantHitTestTarget] collected by
  /// [hitTestElements] in the same order.
  void handleTargetEvent(PointerEvent event, ChantHitTestTarget target);

  /// Override this method if you need to do something when the pointer leaves
  /// the score body.
  void handlePointerExit(PointerExitEvent event) {}

  /// Override this method if you need to do something when the tool is attached
  /// to a score body.
  void handleAttach() {}

  /// Override this method to rebind state after source reparsing.
  void handleScoreUpdated() {}
}

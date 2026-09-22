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

/// Chant score fitting the width constraints of the parent widget.
/// For scrollable widget see [ChantScoreView]
class ChantScoreBody extends LeafRenderObjectWidget {
  /// Creates a read-only chant score body parsed from [gabc].
  const ChantScoreBody({
    super.key,
    required this.gabc,
    this.useDropCap = true,
    this.theme,
  }) : document = null,
       tool = null;

  /// Creates an editable chant score body backed by [document].
  const ChantScoreBody.editable({
    super.key,
    required this.document,
    this.theme,
    this.tool,
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

  @override
  RenderBox createRenderObject(BuildContext context) {
    return RenderChantScore(
      gabc: gabc,
      document: document,
      useDropCap: useDropCap,
      theme: theme,
      tool: tool,
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
      ..tool = tool;
  }
}

class RenderChantScore extends RenderBox implements MouseTrackerAnnotation {
  RenderChantScore({
    required String gabc,
    required ChantDocument? document,
    required bool? useDropCap,
    required ChantTheme? theme,
    required Tool? tool,
  }) : _gabc = gabc,
       _ownsDocument = document == null,
       _useDropCap = useDropCap,
       _tool = tool {
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

  final ChantContext _chantContext = ChantContext();
  late ChantDocument _document;
  final bool _ownsDocument;
  bool _inLayout = false;

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
    _tool?.handleScoreUpdated();
    markNeedsLayout();
  }

  /// The score held by [document].
  ChantScore get score => _document.score;

  void _handleDocumentChanged() {
    if (_inLayout) return;
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

  @override
  void dispose() {
    _document.score.removeListener(_handleDocumentChanged);
    super.dispose();
  }

  @override
  void performLayout() {
    _inLayout = true;
    final selection = score.selection;
    score.performLayout(_chantContext);
    score.layoutChantLines(_chantContext, constraints.maxWidth);
    score.updateSelection(selection);
    _inLayout = false;
    _tool?.handleScoreUpdated();
    size = constraints.constrain(Size(score.bounds.width, score.bounds.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _chantContext.attachCanvas(canvas);
    score.draw(_chantContext);
    canvas.restore();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      tool?.hitTestElements(result, position: position) ??
      super.hitTest(result, position: position);

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

  /// Override this getter to change the cursor display when this tool is active.
  MouseCursor get cursor => MouseCursor.defer;

  /// Determines a set of [ChantLayoutElement]s that are located at the given
  /// position or are relevant to it in the order from the innermost to
  /// the outermost.
  bool hitTestElements(BoxHitTestResult result, {required Offset position}) {
    final globalPosition = Point(position.dx, position.dy);
    if (score.titles?.bounds.containsPoint(globalPosition) ?? false) {
      for (final t in score.titles!.elements) {
        if (t.boundsForHitTest.containsPoint(globalPosition)) {
          result.add(ChantHitTestEntry(t, renderObject));
          result.add(ChantHitTestEntry(score, renderObject));
          result.add(BoxHitTestEntry(renderObject, position));
          return true;
        }
      }
    }

    if (score.dropCap case DropCap(:final boundsForHitTest)) {
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

    for (final line in score.lines) {
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

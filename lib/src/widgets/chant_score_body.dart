/// @docImport 'chant_score_view.dart';
/// @docImport '../elements/chant_layout_element.dart';
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../chant_context.dart';
import '../chant_mapping.dart';
import '../chant_score.dart';
import '../chant_theme.dart';
import '../core.dart';
import '../elements/annotations.dart';
import '../elements/notation/neumes/neume.dart';
import '../elements/text/drop_cap.dart';
import '../gabc.dart';

/// Chant score fitting the width constraints of the parent widget.
/// For scrollable widget see [ChantScoreView]
class ChantScoreBody extends LeafRenderObjectWidget {
  const ChantScoreBody({
    super.key,
    required this.gabc,
    this.useDropCap = true,
    this.theme,
    this.tool,
  });

  final String gabc;
  final bool useDropCap;
  final ChantTheme? theme;
  final Tool? tool;

  @override
  RenderBox createRenderObject(BuildContext context) {
    return RenderChantScore(
      gabc: gabc,
      useDropCap: useDropCap,
      theme: theme ?? ChantTheme.kDefaultTheme,
      tool: tool,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderBox renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as RenderChantScore)
      ..gabc = gabc
      ..useDropCap = useDropCap
      ..theme = theme ?? ChantTheme.kDefaultTheme
      ..tool = tool;
  }
}

class RenderChantScore extends RenderBox {
  RenderChantScore({
    required String gabc,
    required bool useDropCap,
    required ChantTheme theme,
    required Tool? tool,
  }) : _gabc = gabc,
       _chantContext = ChantContext(theme: theme),
       _useDropCap = useDropCap,
       _tool = tool {
    _tool?._attachTo(this);
    _buildScore();
  }

  String _gabc;
  bool _useDropCap;
  Tool? _tool;

  final ChantContext _chantContext;
  late ChantScore _score;
  bool _needsRebuild = true;

  String get gabc => _gabc;
  set gabc(String value) {
    if (value == _gabc) return;
    _gabc = value;
    _score.updateHeader(_chantContext, GabcHeader.fromSource(_gabc));
    Gabc.updateMappingsFromSource(_chantContext, _score.mappings, _gabc);
    _score.updateNotations(_chantContext);
    markNeedsLayout();
  }

  bool get useDropCap => _useDropCap;
  set useDropCap(bool value) {
    if (value == _useDropCap) return;
    _useDropCap = value;
    _needsRebuild = true;
    markNeedsLayout();
  }

  Tool? get tool => _tool;
  set tool(Tool? value) {
    if (value == _tool) return;
    _tool = value;
    _tool?._attachTo(this);
  }

  ChantTheme get theme => _chantContext.theme;
  set theme(ChantTheme value) {
    if (value == _chantContext.theme) return;
    _chantContext.theme = value;
    _needsRebuild = true;
    markNeedsLayout();
  }

  void _buildScore() {
    final List<ChantMapping> mappings = Gabc.createMappingsFromSource(
      _chantContext,
      _gabc,
    );
    _score = ChantScore(
      ctxt: _chantContext,
      mappings: mappings,
      header: GabcHeader.fromSource(_gabc),
      useDropCap: _useDropCap,
    );
    _needsRebuild = false;
  }

  @override
  void performLayout() {
    if (_needsRebuild) _buildScore();
    _score.performLayout(_chantContext);
    _score.layoutChantLines(_chantContext, constraints.maxWidth);
    size = constraints.constrain(
      Size(_score.bounds.width, _score.bounds.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _chantContext.attachCanvas(canvas);
    _score.draw(_chantContext);
    canvas.restore();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      tool?.hitTestElements(result, position: position) ??
      super.hitTest(result, position: position);
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
  }

  /// Render object that this tool is attached to.
  RenderChantScore get renderObject => _renderObject;

  /// Score this tool is editing.
  ChantScore get score => _renderObject._score;

  /// Chant context of the edited score.
  ChantContext get chantContext => _renderObject._chantContext;

  /// Determines a set of [ChantLayoutElement]s that are located at the given
  /// position or are relevant to it in the order from the innermost to
  /// the outermost.
  bool hitTestElements(BoxHitTestResult result, {required Offset position}) {
    final globalPosition = Point(position.dx, position.dy);
    if (score.titles?.bounds.containsPoint(globalPosition) ?? false) {
      for (final t in score.titles!.elements) {
        if (t.boundsForHitTest.containsPoint(globalPosition)) {
          result.add(ChantHitTestEntry(t, renderObject));
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
        if (line.startingClef?.bounds.containsPoint(linePosition) ?? false) {
          result.add(ChantHitTestEntry(line.startingClef!, renderObject));
        } else {
          for (
            int i = line.notationsStartIndex;
            i < line.notationsStartIndex + line.numNotationsOnLine;
            i++
          ) {
            final element = score.notations[i];
            if (element.bounds.containsPoint(linePosition)) {
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
      return true;
    }

    return false;
  }

  /// Override this method to handle pointer events.
  ///
  /// This method is is called for each [ChantHitTestTarget] collected by
  /// [hitTestElements] in the same order.
  void handleTargetEvent(PointerEvent event, ChantHitTestTarget target);
}

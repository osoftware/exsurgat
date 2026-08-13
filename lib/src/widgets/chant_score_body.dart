/// @docImport 'chant_score_view.dart';
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
import '../elements/chant_layout_element.dart';
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
    this.editable = false,
  });

  final String gabc;
  final bool useDropCap;
  final ChantTheme? theme;
  final bool editable;

  @override
  RenderBox createRenderObject(BuildContext context) {
    return _ChantScoreRenderBox(
      gabc: gabc,
      useDropCap: useDropCap,
      theme: theme ?? ChantTheme.kDefaultTheme,
      editable: editable,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderBox renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _ChantScoreRenderBox)
      ..gabc = gabc
      ..useDropCap = useDropCap
      ..theme = theme ?? ChantTheme.kDefaultTheme;
  }
}

class _ChantScoreRenderBox extends RenderBox {
  _ChantScoreRenderBox({
    required String gabc,
    required bool useDropCap,
    required ChantTheme theme,
    required bool editable,
  }) : _gabc = gabc,
       _chantContext = ChantContext(theme: theme),
       _useDropCap = useDropCap,
       _editable = editable {
    _buildScore();
  }

  String _gabc;
  bool _useDropCap;
  bool _editable;

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

  bool get editable => _editable;
  set editable(bool value) {
    if (value == _editable) return;
    _editable = value;
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
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return super.hitTest(result, position: position) ||
        _editable && hitTestNotationElements(result, position: position);
  }

  bool hitTestNotationElements(
    BoxHitTestResult result, {
    required Offset position,
  }) {
    final globalPosition = Point(position.dx, position.dy);
    if (_score.titles?.bounds.containsPoint(globalPosition) ?? false) {
      for (final t in _score.titles!.elements) {
        if (t.boundsForHitTest.containsPoint(globalPosition)) {
          result.add(ChantHitTestEntry(t, _chantContext));
          return true;
        }
      }
    }

    if (_score.dropCap case DropCap(:final boundsForHitTest)) {
      final dropCapBounds = boundsForHitTest.copyWith(
        y: boundsForHitTest.y + _score.lines.first.bounds.y,
      );
      if (dropCapBounds.containsPoint(globalPosition)) {
        result.add(ChantHitTestEntry(_score.dropCap!, _chantContext));
        return true;
      }
      if (_score.annotation case Annotations(:final annotations)) {
        for (final a in annotations) {
          final aBounds = a.boundsForHitTest.copyWith(
            y: a.boundsForHitTest.y + _score.lines.first.boundsForHitTest.y,
            x: a.boundsForHitTest.x + _score.annotation!.bounds.x,
          );
          if (aBounds.containsPoint(globalPosition)) {
            result.add(ChantHitTestEntry(a, _chantContext));
            return true;
          }
        }
      }
    }

    for (final line in _score.lines) {
      if (line.boundsForHitTest.containsPoint(globalPosition)) {
        final linePosition = Point(
          globalPosition.x - line.bounds.x,
          globalPosition.y - line.bounds.y,
        );
        if (line.startingClef?.bounds.containsPoint(linePosition) ?? false) {
          result.add(ChantHitTestEntry(line.startingClef!, _chantContext));
        } else {
          for (
            int i = line.notationsStartIndex;
            i < line.notationsStartIndex + line.numNotationsOnLine;
            i++
          ) {
            final element = _score.notations[i];
            if (element.bounds.containsPoint(linePosition)) {
              if (element case Neume(:final notes)) {
                for (final note in notes.reversed) {
                  final noteBounds = note.bounds.copyWith(
                    x: element.bounds.x + note.bounds.x,
                  );
                  if (noteBounds.containsPoint(linePosition)) {
                    result.add(ChantHitTestEntry(note, _chantContext));
                    break;
                  }
                }
              }

              result.add(ChantHitTestEntry(element, _chantContext));
              break;
            }
          }
        }

        result.add(ChantHitTestEntry(line, _chantContext));
        return true;
      }
    }

    return false;
  }
}

class ChantHitTestTarget implements HitTestTarget {
  ChantHitTestTarget(this.target);
  ChantLayoutElement target;
  @override
  void handleEvent(PointerEvent event, covariant ChantHitTestEntry entry) {}
}

class ChantHitTestEntry extends HitTestEntry<ChantHitTestTarget> {
  ChantHitTestEntry(ChantLayoutElement target, this.ctxt)
    : super(ChantHitTestTarget(target));
  final ChantContext ctxt;
}

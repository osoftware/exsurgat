import 'package:flutter/widgets.dart';

import '../chant_context.dart';
import '../chant_mapping.dart';
import '../chant_score.dart';
import '../gabc.dart';

/// Chant score fitting the width constrint of the parent widget.
class ChantScoreBody extends LeafRenderObjectWidget {
  const ChantScoreBody({super.key, required this.gabc, this.useDropCap = true});

  final String gabc;
  final bool useDropCap;

  @override
  RenderBox createRenderObject(BuildContext context) {
    return _ChantScoreRenderBox(gabc: gabc, useDropCap: useDropCap);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBox renderObject) {
    (renderObject as _ChantScoreRenderBox)
      ..gabc = gabc
      ..useDropCap = useDropCap;
  }
}

class _ChantScoreRenderBox extends RenderBox {
  _ChantScoreRenderBox({required String gabc, required bool useDropCap})
    : _gabc = gabc,
      _useDropCap = useDropCap {
    _chantContext = ChantContext();
    _rebuildScore();
  }

  late final ChantContext _chantContext;
  late ChantScore _score;
  String _gabc;
  bool _useDropCap;
  bool _needsRebuild = true;

  String get gabc => _gabc;
  set gabc(String value) {
    if (value == _gabc) return;
    _gabc = value;
    _needsRebuild = true;
    markNeedsLayout();
  }

  bool get useDropCap => _useDropCap;
  set useDropCap(bool value) {
    if (value == _useDropCap) return;
    _useDropCap = value;
    _needsRebuild = true;
    markNeedsLayout();
  }

  void _rebuildScore() {
    final List<ChantMapping> mappings = Gabc.createMappingsFromSource(
      _chantContext,
      _gabc,
    );
    _score = ChantScore(
      ctxt: _chantContext,
      mappings: mappings,
      header: GabcHeader(_gabc),
      useDropCap: _useDropCap,
    );
    _needsRebuild = false;
  }

  @override
  void performLayout() {
    if (_needsRebuild) _rebuildScore();
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
}

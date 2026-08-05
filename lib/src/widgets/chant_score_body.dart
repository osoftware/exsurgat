/// @docImport 'chant_score_view.dart';
library;

import 'package:flutter/widgets.dart';

import '../chant_context.dart';
import '../chant_mapping.dart';
import '../chant_score.dart';
import '../chant_theme.dart';
import '../gabc.dart';

/// Chant score fitting the width constrint of the parent widget.
/// For scrollable widget see [ChantScoreView]
class ChantScoreBody extends LeafRenderObjectWidget {
  const ChantScoreBody({
    super.key,
    required this.gabc,
    this.useDropCap = true,
    this.theme,
  });

  final String gabc;
  final bool useDropCap;
  final ChantTheme? theme;

  @override
  RenderBox createRenderObject(BuildContext context) {
    return _ChantScoreRenderBox(
      gabc: gabc,
      useDropCap: useDropCap,
      theme: theme ?? ChantTheme.kDefaultTheme,
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
  }) : _gabc = gabc,
       _chantContext = ChantContext(theme: theme),
       _useDropCap = useDropCap {
    _buildScore();
  }

  final ChantContext _chantContext;
  late ChantScore _score;
  String _gabc;
  bool _useDropCap;
  bool _needsRebuild = true;

  String get gabc => _gabc;
  set gabc(String value) {
    if (value == _gabc) return;
    _gabc = value;
    _score.updateHeader(_chantContext, GabcHeader(_gabc));
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
      header: GabcHeader(_gabc),
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
}

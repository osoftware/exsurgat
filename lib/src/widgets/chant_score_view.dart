import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../chant_document.dart';
import '../chant_mapping.dart';
import '../chant_score.dart';
import '../drawing.dart';
import '../gabc.dart';
import 'chant_painter.dart';

class ChantScoreView extends StatefulWidget {
  const ChantScoreView({
    super.key,
    required this.gabc,
    this.useDropCap = true,
    this.width = 300,
    this.useNativeRendering = false,
  });

  final String gabc;
  final bool useDropCap;
  final double width;
  final bool useNativeRendering;

  @override
  State<ChantScoreView> createState() => _ChantScoreViewState();
}

class _ChantScoreViewState extends State<ChantScoreView> {
  late final ChantContext _chantContext;
  late ChantScore _score;
  late List<ChantMapping> _mappings;
  late String _xml;

  @override
  void initState() {
    super.initState();
    _chantContext = ChantContext(
      textMeasuringStrategy: widget.useNativeRendering ? .canvas : .svg,
    );
  }

  String _makeScore(double width) {
    _mappings = Gabc.createMappingsFromSource(_chantContext, widget.gabc);
    _score = ChantScore(
      ctxt: _chantContext,
      mappings: _mappings,
      header: GabcHeader(widget.gabc),
      useDropCap: widget.useDropCap,
    );
    ChantDocument();
    return _layoutScore(width);
  }

  String _layoutScore(double width) {
    _score.performLayout(_chantContext);
    _score.layoutChantLines(_chantContext, width);
    return _renderScore();
  }

  String _renderScore() {
    return widget.useNativeRendering
        ? ''
        : _score.createSvgNode(_chantContext).toXmlString();
  }

  @override
  void didUpdateWidget(covariant ChantScoreView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.useNativeRendering != oldWidget.useNativeRendering) {
      _chantContext.textMeasuringStrategy = widget.useNativeRendering
          ? .canvas
          : .svg;
    }
    if (widget.gabc != oldWidget.gabc ||
        widget.useDropCap != oldWidget.useDropCap) {
      _xml = _makeScore(widget.width);
    } else if (widget.width != oldWidget.width) {
      _xml = _layoutScore(widget.width);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _xml = _makeScore(widget.width);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      // child: ,
      child: widget.useNativeRendering
          ? SizedBox(
              width: widget.width,
              child: FittedBox(
                child: CustomPaint(
                  size: Size(widget.width, _score.bounds.height),
                  painter: ChantPainter(_score, _chantContext),
                ),
              ),
            )
          : SvgPicture.string(_xml),
    );
  }
}

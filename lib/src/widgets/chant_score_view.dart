import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../chant_mapping.dart';
import '../chant_score.dart';
import '../drawing.dart';
import '../gabc.dart';

class ChantScoreView extends StatefulWidget {
  const ChantScoreView({
    super.key,
    required this.gabc,
    this.useDropCap = true,
    this.width = 300,
  });

  final String gabc;
  final bool useDropCap;
  final double width;

  @override
  State<ChantScoreView> createState() => _ChantScoreViewState();
}

class _ChantScoreViewState extends State<ChantScoreView> {
  final _chantContext = ChantContext(textMeasuringStrategy: .canvas);
  late ChantScore _score;
  late List<ChantMapping> _mappings;
  late String _xml;

  String _makeScore(double width) {
    _mappings = Gabc.createMappingsFromSource(_chantContext, widget.gabc);
    return _setupScore(width);
  }

  String _setupScore(double width) {
    _score = ChantScore(
      ctxt: _chantContext,
      mappings: _mappings,
      useDropCap: widget.useDropCap,
    );
    _score.performLayout(_chantContext);
    return _layoutScore(width);
  }

  String _layoutScore(double width) {
    _score.layoutChantLines(_chantContext, width);
    return _renderScore();
  }

  String _renderScore() {
    return _score.createSvgNode(_chantContext).toXmlString();
  }

  @override
  void didUpdateWidget(covariant ChantScoreView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gabc != oldWidget.gabc) {
      _xml = _makeScore(widget.width);
    } else if (widget.useDropCap != oldWidget.useDropCap) {
      _xml = _setupScore(widget.width);
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
      padding: const EdgeInsets.all(8.0),
      child: SvgPicture.string(_xml),
    );
  }
}

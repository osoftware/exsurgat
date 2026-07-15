import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../chant_score.dart';
import '../drawing.dart';
import '../gabc.dart';

class ChantScoreView extends StatefulWidget {
  const ChantScoreView({super.key, required this.gabc});

  final String gabc;

  @override
  State<ChantScoreView> createState() => _ChantScoreViewState();
}

class _ChantScoreViewState extends State<ChantScoreView> {
  final chantContext = ChantContext(textMeasuringStrategy: .canvas);
  late String xml;

  @override
  initState() {
    super.initState();

    xml = renderSvg();
  }

  String renderSvg() {
    final mappings = Gabc.createMappingsFromSource(chantContext, widget.gabc);
    final score = ChantScore(ctxt: chantContext, mappings: mappings);
    score.useDropCap = true;
    score.performLayout(chantContext);
    score.layoutChantLines(chantContext, 300);
    return score.createSvgNode(chantContext).toXmlString();
  }

  @override
  void didUpdateWidget(covariant ChantScoreView oldWidget) {
    super.didUpdateWidget(oldWidget);
    xml = renderSvg();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.widthOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SvgPicture.string(xml),
    );
  }
}

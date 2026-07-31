import 'package:exsurgat/exsurgat.dart';
import 'package:flutter/material.dart';

/// Scrollable chant score with configurable width.
class ChantScoreView extends StatelessWidget {
  const ChantScoreView({
    super.key,
    required this.gabc,
    this.useDropCap = true,
    this.width = 600,
    this.useNativeRendering = true,
  });

  final String gabc;
  final bool useDropCap;
  final double width;
  final bool useNativeRendering;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: width,
        child: ChantScoreBody(gabc: gabc, useDropCap: useDropCap),
      ),
    );
  }
}

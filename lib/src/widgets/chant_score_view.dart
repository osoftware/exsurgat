import 'package:flutter/widgets.dart';

import '../chant_theme.dart';
import 'chant_score_body.dart';

/// Scrollable chant score with configurable width and padding.
class ChantScoreView extends StatelessWidget {
  const ChantScoreView({
    super.key,
    required this.gabc,
    this.useDropCap = true,
    this.width,
    this.padding = const EdgeInsets.all(12),
    this.theme,
    this.editable = false,
  });

  final String gabc;
  final bool useDropCap;
  final double? width;
  final EdgeInsets padding;
  final ChantTheme? theme;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: padding,
          child: ChantScoreBody(
            gabc: gabc,
            useDropCap: useDropCap,
            theme: theme,
            editable: editable,
          ),
        ),
      ),
    );
  }
}

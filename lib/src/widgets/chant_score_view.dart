import 'package:flutter/widgets.dart';

import '../chant_theme.dart';
import 'chant_score_body.dart';

/// Scrollable chant score with configurable width and padding.
class ChantScoreView extends StatelessWidget {
  const ChantScoreView({
    super.key,
    required this.gabc,
    this.width,
    this.padding = const EdgeInsets.all(12),
    this.theme,
  });

  /// Source to render.
  final String gabc;

  /// Width of the score sheet.
  final double? width;

  /// Inner padding of the score sheet.
  final EdgeInsets padding;

  /// Theme to apply on the score.
  ///
  /// If provided, overrides the theme defined in [gabc] header.
  final ChantTheme? theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: padding,
          child: ChantScoreBody(gabc: gabc, theme: theme),
        ),
      ),
    );
  }
}

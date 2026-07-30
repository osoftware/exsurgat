import 'chant_context.dart';

/// A trailing space value that may be either a fixed double or a function
/// computed from the [ChantContext].
class TrailingSpace {
  TrailingSpace(this._value, {this.isDefault = false});

  factory TrailingSpace.value(double value, {bool isDefault = false}) =>
      TrailingSpace((_) => value, isDefault: isDefault);

  factory TrailingSpace.multiple(double multiplier) =>
      TrailingSpace((ctxt) => ctxt.intraNeumeSpacing * multiplier);

  final double Function(ChantContext ctxt) _value;
  final bool isDefault;

  double call(ChantContext ctxt) => _value(ctxt);

  static final TrailingSpace zero = TrailingSpace.value(0);

  /// The default trailing space applied to notations, computed from the
  /// [ChantContext].
  static final defaultTrailingSpace = TrailingSpace(
    (ctxt) => ctxt.intraNeumeSpacing * ctxt.interSyllabicMultiplier,
    isDefault: true,
  );

  static final forAccidental = TrailingSpace(
    (ctxt) => ctxt.intraNeumeSpacing * ctxt.accidentalSpaceMultiplier,
  );
}

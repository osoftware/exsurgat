import 'chant_context.dart';

/// A trailing space value applied after a notation.
sealed class TrailingSpace {
  const TrailingSpace();

  /// Computes the effective space size within [ctxt].
  double call(ChantContext ctxt);

  /// Whether this is the default trailing space applied to notations.
  bool get isDefault => this is TrailingSpaceDefault;

  /// Gabc string that produces this space.
  String toGabcString() => '';

  /// Trailing space of fixed [value] regardless of [ChantContext].
  const factory TrailingSpace.value(double value) = TrailingSpaceValue;

  /// No trailing space.
  ///
  /// Used in specific contexts, like end of score or befor quilisma.
  static const TrailingSpace zero = TrailingSpace.value(0);

  /// Default trailing space after a neume.
  ///
  /// Computed from [ChantContext].
  static const TrailingSpace defaultTrailingSpace = TrailingSpaceDefault();

  /// Default trailing space after an accidental or custos.
  ///
  /// Computed from [ChantContext].
  static const TrailingSpace forAccidental = TrailingSpaceForAccidental();

  /// A trailing space that is a multiple of [ChantContext.intraNeumeSpacing].
  ///
  /// The only type of trailing space that is forced by explicit notation
  /// `!', `/`, `//`, ' ', `/0`, `/[n]` in gabc.
  const factory TrailingSpace.multiple(double multiplier) =
      TrailingSpaceMultiple;
}

/// Trailing space of fixed [value].
final class TrailingSpaceValue extends TrailingSpace {
  const TrailingSpaceValue(this.value);

  final double value;

  @override
  double call(ChantContext ctxt) => value;
}

/// A trailing space that is a multiple of [ChantContext.intraNeumeSpacing].
///
/// The only type of trailing space that is forced by explicit notation
/// `!', `/`, `//`, ' ', `/0`, `/[n]` in gabc.
final class TrailingSpaceMultiple extends TrailingSpace {
  const TrailingSpaceMultiple(this.multiplier);

  final double multiplier;

  @override
  double call(ChantContext ctxt) => ctxt.intraNeumeSpacing * multiplier;

  @override
  String toGabcString() => switch (multiplier) {
    0 => '!',
    0.5 => '/0',
    1 => '/',
    2 => ' ',
    _ => '/[$multiplier]',
  };
}

/// Default trailing space after a neume.
///
/// Computed from [ChantContext].
final class TrailingSpaceDefault extends TrailingSpace {
  const TrailingSpaceDefault();

  @override
  double call(ChantContext ctxt) =>
      ctxt.intraNeumeSpacing * ctxt.interSyllabicMultiplier;
}

/// Default trailing space after an accidental or custos.
///
/// Computed from [ChantContext].
final class TrailingSpaceForAccidental extends TrailingSpace {
  const TrailingSpaceForAccidental();

  @override
  double call(ChantContext ctxt) =>
      ctxt.intraNeumeSpacing * ctxt.accidentalSpaceMultiplier;
}

import 'dart:math' as math;

enum Unit {
  deviceIndependent("di", 1.0),
  centimeters("cm", 96.0 / 2.54),
  millimeters("mm", 96.0 / 2.54 / 10.0),
  inches("in", 96.0),
  points("pt", 72.0);

  final String label;
  final double diuPerUnit;

  const Unit(this.label, this.diuPerUnit);

  static const double diuPerInch = 96.0;
  static const double diuPerCentimeter = 96.0 / 2.54;

  double toDeviceIndependent(double n) => n * diuPerUnit;

  double fromDeviceIndependent(double n) => n / diuPerUnit;

  static Unit fromString(String s) {
    return switch (s.toLowerCase()) {
      "in" || "inches" => Unit.inches,
      "cm" || "centimeters" => Unit.centimeters,
      "mm" || "millimeters" => Unit.millimeters,
      "di" || "device-independent" => Unit.deviceIndependent,
      "pt" || "points" => Unit.points,
      _ => Unit.deviceIndependent,
    };
  }

  @override
  String toString() => label;
}

/// A scalar [value] expressed in [unit]s.
class Scalar {
  final double value;
  final Unit unit;

  const Scalar(this.value, [this.unit = Unit.deviceIndependent]);

  double get deviceIndependent => unit.toDeviceIndependent(value);

  /// Converts this [value] to a different [unit]s.
  Scalar toUnit(Unit target) =>
      Scalar(target.fromDeviceIndependent(deviceIndependent), target);

  /// Creates a deep copy of this object.
  Scalar clone() => Scalar(value, unit);

  /// Creates a copy with changed [value] or [unit].
  Scalar copyWith({double? value, Unit? unit}) =>
      Scalar(value ?? this.value, unit ?? this.unit);

  /// Parses strings like `"124.3mm"`, `"2in"`, `"96"`.
  /// No unit suffix means [Unit.deviceIndependent].
  static Scalar parse(String s) {
    final Scalar? result = tryParse(s);
    if (result == null) {
      throw FormatException('Invalid scalar: "$s"');
    }
    return result;
  }

  /// Like [parse] but returns `null` instead of throwing.
  static Scalar? tryParse(String s) {
    final String trimmed = s.trim();
    if (trimmed.isEmpty) return null;

    final RegExpMatch? match = RegExp(
      r'^([+-]?(?:\d+\.?\d*|\.\d+))\s*([a-zA-Z]*)$',
    ).firstMatch(trimmed);
    if (match == null) return null;

    final double? value = double.tryParse(match.group(1)!);
    if (value == null) return null;

    final suffix = match.group(2)!.toLowerCase();
    final unit = Unit.fromString(suffix);
    return Scalar(value, unit);
  }

  /// Adds [other], converting it to this scalar's unit first.
  Scalar operator +(Scalar other) =>
      Scalar(value + other.toUnit(unit).value, unit);

  /// Subtracts [other], converting it to this scalar's unit first.
  Scalar operator -(Scalar other) =>
      Scalar(value - other.toUnit(unit).value, unit);

  /// Multiplies by a unitless factor.
  Scalar operator *(num factor) => Scalar(value * factor, unit);

  /// Divides by a unitless factor.
  Scalar operator /(num factor) => Scalar(value / factor, unit);

  @override
  bool operator ==(covariant Scalar other) =>
      value == other.value && unit == other.unit;

  @override
  int get hashCode => Object.hash(value, unit);

  @override
  String toString() => '$value$unit';
}

interface class Geom {}

/// Position of an element.
///
/// Used internaly by the rendering engine.
class Point implements Geom {
  final double x;
  final double y;

  const Point([this.x = 0.0, this.y = 0.0]);

  Point clone() => Point(x, y);

  Point copyWith({double? x, double? y}) => Point(x ?? this.x, y ?? this.y);

  @override
  String toString() => '($x,$y)';
}

/// Bounding box of an element.
///
/// Used internaly by the rendering engine.
class Rect implements Geom {
  final double x;
  final double y;
  final double width;
  final double height;

  const Rect({
    this.x = double.infinity,
    this.y = double.infinity,
    this.width = double.negativeInfinity,
    this.height = double.negativeInfinity,
  });

  const Rect.fromXYWH(this.x, this.y, this.width, this.height);

  Rect clone() => Rect.fromXYWH(x, y, width, height);

  Rect copyWith({double? x, double? y, double? width, double? height}) =>
      Rect.fromXYWH(
        x ?? this.x,
        y ?? this.y,
        width ?? this.width,
        height ?? this.height,
      );

  double get right => x + width;
  double get bottom => y + height;

  bool get isEmpty =>
      x == double.infinity &&
      y == double.infinity &&
      width == double.negativeInfinity &&
      height == double.negativeInfinity;

  @override
  bool operator ==(covariant Rect other) =>
      x == other.x &&
      y == other.y &&
      width == other.width &&
      height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  bool contains(Geom other) {
    return switch (other) {
      Point() => containsPoint(other),
      Rect() => containsRect(other),
      _ => false,
    };
  }

  bool containsPoint(Point other) =>
      other.x >= x && other.x <= right && other.y >= y && other.y <= bottom;

  bool containsRect(Rect other) {
    return other.x >= x &&
        other.right <= right &&
        other.y >= y &&
        other.bottom <= bottom;
  }

  Rect operator +(Rect other) {
    final double newX = math.min(x, other.x);
    final double newY = math.min(y, other.y);
    final double newRight = math.max(right, other.right);
    final double newBottom = math.max(bottom, other.bottom);
    return Rect.fromXYWH(newX, newY, newRight - newX, newBottom - newY);
  }

  @override
  String toString() => '($x,$y,$width,$height)';
}

/// Steps of the musical scale.
enum Step {
  ut(0),
  du(1),
  re(2),
  me(3),
  mi(4),
  fa(5),
  fu(6),
  so(7),
  __invalid(8),
  la(9),
  te(10),
  ti(11);

  final int value;
  const Step(this.value);
}

/// Musical pitch.
class Pitch {
  final Step step;
  final int octave;

  Pitch(int step, [int? octave])
    : step = Step.values[octave == null ? step % 12 : step],
      octave = octave ?? (step ~/ 12);

  /// Converts the pitch to the corresponding MIDI note.
  int toInt() => octave * 12 + step.value;

  Pitch transpose(int stepDelta) => Pitch(toInt() + stepDelta);

  bool operator >(Pitch other) => toInt() > other.toInt();

  bool operator <(Pitch other) => toInt() < other.toInt();

  @override
  bool operator ==(covariant Pitch other) => toInt() == other.toInt();

  @override
  int get hashCode => toInt().hashCode;

  static const List<int> _stepToStaffPosition = [
    0,
    0,
    1,
    1,
    2,
    3,
    3,
    4,
    4,
    5,
    6,
    6,
  ];
  static const List<Step> _staffOffsetToStep = [
    Step.ut,
    Step.re,
    Step.mi,
    Step.fa,
    Step.so,
    Step.la,
    Step.ti,
  ];

  static int stepToStaffOffset(Step step) {
    return _stepToStaffPosition[step.value];
  }

  static Step staffOffsetToStep(int offset) {
    int adjustedOffset = offset;
    while (adjustedOffset < 0) {
      adjustedOffset += _staffOffsetToStep.length;
    }
    return _staffOffsetToStep[adjustedOffset % _staffOffsetToStep.length];
  }
}

/// Bitfield capability for enums.
mixin Flags on Enum {
  int get value;

  bool hasFlag(Flags flag) => (value & flag.value) != 0;
  bool hasAnyFlag(int flags) => (value & flags) != 0;

  int operator |(Flags other) => value | other.value;
}

/// Combines a [Flags] enum value with an [int] (result of `|` operator) and
/// returns the combined int value. Used for setting flags on Note fields.
int combineFlags(int current, Flags flag) => current | flag.value;

/// Returns true if [flags] (an int) has the given [flag] set.
bool hasFlag(int flags, Flags flag) => (flags & flag.value) != 0;

/// Returns true if [flags] (an int) has any of the given [mask] bits set.
bool hasAnyFlag(int flags, int mask) => (flags & mask) != 0;

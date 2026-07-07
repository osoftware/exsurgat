import 'dart:math' as math;

enum UnitsType { deviceIndependent, centimeters, millimeters, inches }

class Units {
  static const double diuPerInch = 96.0;
  static const double diuPerCentimeter = 96.0 / 2.54;

  static double toDeviceIndependent(double n, UnitsType inputUnits) {
    return switch (inputUnits) {
      UnitsType.centimeters => n * diuPerCentimeter,
      UnitsType.millimeters => n * diuPerCentimeter / 10.0,
      UnitsType.inches => n * diuPerInch,
      UnitsType.deviceIndependent => n,
    };
  }

  static double fromDeviceIndependent(double n, UnitsType outputUnits) {
    return switch (outputUnits) {
      UnitsType.centimeters => n / diuPerCentimeter,
      UnitsType.millimeters => n / diuPerCentimeter * 10.0,
      UnitsType.inches => n / diuPerInch,
      UnitsType.deviceIndependent => n,
    };
  }

  static UnitsType stringToUnitsType(String s) {
    return switch (s.toLowerCase()) {
      "in" || "inches" => UnitsType.inches,
      "cm" || "centimeters" => UnitsType.centimeters,
      "mm" || "millimeters" => UnitsType.millimeters,
      "di" || "device-independent" => UnitsType.deviceIndependent,
      _ => UnitsType.deviceIndependent,
    };
  }

  static String unitsTypeToString(UnitsType units) {
    return switch (units) {
      UnitsType.inches => "in",
      UnitsType.centimeters => "cm",
      UnitsType.millimeters => "mm",
      UnitsType.deviceIndependent => "device-independent",
    };
  }
}

interface class Geom {}

class Point implements Geom {
  final double x;
  final double y;

  const Point([this.x = 0.0, this.y = 0.0]);

  Point clone() => Point(x, y);

  Point copyWith({double? x, double? y}) => Point(x ?? this.x, y ?? this.y);

  bool equals(Point other) => x == other.x && y == other.y;
}

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

  Rect union(Rect other) {
    final double newX = math.min(x, other.x);
    final double newY = math.min(y, other.y);
    final double newRight = math.max(right, other.right);
    final double newBottom = math.max(bottom, other.bottom);
    return Rect.fromXYWH(newX, newY, newRight - newX, newBottom - newY);
  }
}

class Margins {
  final double left;
  final double top;
  final double right;
  final double bottom;

  Margins([
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
  ]);

  Margins clone() => Margins(left, top, right, bottom);

  bool equals(Margins other) =>
      left == other.left &&
      top == other.top &&
      right == other.right &&
      bottom == other.bottom;
}

class Size {
  final double width;
  final double height;

  Size([this.width = 0.0, this.height = 0.0]);

  Size clone() => Size(width, height);

  bool equals(Size other) => width == other.width && height == other.height;
}

enum Step {
  ut(0),
  du(1),
  re(2),
  me(3),
  mi(4),
  fa(5),
  fu(6),
  so(7),
  la(9),
  te(10),
  ti(11);

  final int value;
  const Step(this.value);
}

class Pitch {
  final Step step;
  final int octave;

  Pitch(int step, [int? octave])
    : step = Step.values[octave == null ? step % 12 : step],
      octave = octave ?? (step ~/ 12);

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

String getCssForProperties(Map<String, dynamic> properties) {
  return properties.entries
      .where((entry) => entry.key != 'class' && entry.value != null)
      .map((entry) => '${entry.key}: ${entry.value};')
      .join();
}

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

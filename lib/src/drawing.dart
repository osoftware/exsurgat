import 'dart:ui';

String resolveFontFilenameForProperties(
  Map<String, dynamic> properties, [
  String? fontFamily,
]) {
  return fontFamily ?? 'Regular';
}

extension CanvasPathBuilderExtension on Canvas {
  CanvasPathBuilder beginPath({
    required double strokeWidth,
    required Color color,
  }) => CanvasPathBuilder(this, strokeWidth: strokeWidth, color: color);
}

/// Mimic HTML5 canvas
class CanvasPathBuilder {
  final Path _path = Path();
  final Canvas _canvas;
  bool _disposed = false;

  double strokeWidth;
  Color color;

  CanvasPathBuilder(
    this._canvas, {
    required this.strokeWidth,
    required this.color,
  });

  void moveTo(double x, double y) {
    _path.moveTo(x, y);
  }

  void lineTo(double x, double y) {
    _path.lineTo(x, y);
  }

  void stroke() {
    if (_disposed) {
      throw StateError('This path has already been drawn.');
    }
    _canvas.drawPath(
      _path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = strokeWidth,
    );
    _disposed = true;
  }
}

extension Svg on Color {
  String toSvgString() {
    final hex = toARGB32().toRadixString(16);
    return "#${hex.substring(2)}${hex.substring(0, 2)}";
  }
}

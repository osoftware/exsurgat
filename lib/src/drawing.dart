import 'dart:ui';

extension CanvasPathExtensions on Canvas {
  CanvasPathBuilder beginPath({
    required double strokeWidth,
    required Color color,
  }) => CanvasPathBuilder(this, strokeWidth: strokeWidth, color: color);

  void drawSvgPath(String path, Paint paint) =>
      drawPath(parseSvgPath(path), paint);
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
  /// Returns a CSS and SVG compatible color string.
  String toSvgString() {
    final hex = toARGB32().toRadixString(16);
    return "#${hex.substring(2)}${hex.substring(0, 2)}";
  }
}

Path parseSvgPath(String data) {
  final path = Path();
  if (data.trim().isEmpty) {
    return path;
  }

  // Match either a single command letter or a number (incl. scientific
  // notation, leading sign, and leading dot like ".5").
  final tokenPattern = RegExp(
    r'[MmLlCcQqSsTtAaHhVvZz]|-?\d*\.?\d+(?:[eE][+-]?\d+)?',
  );
  final tokens = tokenPattern
      .allMatches(data)
      .map((match) => match.group(0)!)
      .toList();
  if (tokens.isEmpty) {
    return path;
  }

  var index = 0;
  // Current command. Empty means none seen yet.
  var command = '';
  double currentX = 0;
  double currentY = 0;
  double subpathX = 0;
  double subpathY = 0;
  // Last control point of a C/S/Q/T command, for smooth-curve reflection.
  double prevCtrlX = 0;
  double prevCtrlY = 0;

  bool isCommand(String t) =>
      t.length == 1 && RegExp(r'[MmLlCcQqSsTtAaHhVvZz]').hasMatch(t);

  double nextNum() => double.parse(tokens[index++]);

  void resetControl() {
    prevCtrlX = currentX;
    prevCtrlY = currentY;
  }

  while (index < tokens.length) {
    final t = tokens[index];
    if (isCommand(t)) {
      command = t;
      index++;
    }
    // Otherwise: implicit repeat of the previous command.

    final upper = command.toUpperCase();
    final absolute = upper == command;

    switch (upper) {
      case 'M':
        {
          final x = nextNum();
          final y = nextNum();
          currentX = absolute ? x : currentX + x;
          currentY = absolute ? y : currentY + y;
          subpathX = currentX;
          subpathY = currentY;
          path.moveTo(currentX, currentY);
          resetControl();
          // Subsequent coordinate pairs after M are implicit lineto.
          command = absolute ? 'L' : 'l';
          break;
        }
      case 'L':
        {
          final x = nextNum();
          final y = nextNum();
          final nx = absolute ? x : currentX + x;
          final ny = absolute ? y : currentY + y;
          path.lineTo(nx, ny);
          currentX = nx;
          currentY = ny;
          resetControl();
          break;
        }
      case 'H':
        {
          final x = nextNum();
          final nx = absolute ? x : currentX + x;
          path.lineTo(nx, currentY);
          currentX = nx;
          resetControl();
          break;
        }
      case 'V':
        {
          final y = nextNum();
          final ny = absolute ? y : currentY + y;
          path.lineTo(currentX, ny);
          currentY = ny;
          resetControl();
          break;
        }
      case 'C':
        {
          final c1x = nextNum();
          final c1y = nextNum();
          final c2x = nextNum();
          final c2y = nextNum();
          final ex = nextNum();
          final ey = nextNum();
          final x1 = absolute ? c1x : currentX + c1x;
          final y1 = absolute ? c1y : currentY + c1y;
          final x2 = absolute ? c2x : currentX + c2x;
          final y2 = absolute ? c2y : currentY + c2y;
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.cubicTo(x1, y1, x2, y2, nx, ny);
          prevCtrlX = x2;
          prevCtrlY = y2;
          currentX = nx;
          currentY = ny;
          break;
        }
      case 'S':
        {
          final c2x = nextNum();
          final c2y = nextNum();
          final ex = nextNum();
          final ey = nextNum();
          // Reflected control point (equals current point if prev was not
          // a C/S command, since resetControl set prevCtrl = current).
          final x1 = 2 * currentX - prevCtrlX;
          final y1 = 2 * currentY - prevCtrlY;
          final x2 = absolute ? c2x : currentX + c2x;
          final y2 = absolute ? c2y : currentY + c2y;
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.cubicTo(x1, y1, x2, y2, nx, ny);
          prevCtrlX = x2;
          prevCtrlY = y2;
          currentX = nx;
          currentY = ny;
          break;
        }
      case 'Q':
        {
          final cx = nextNum();
          final cy = nextNum();
          final ex = nextNum();
          final ey = nextNum();
          final controlX = absolute ? cx : currentX + cx;
          final controlY = absolute ? cy : currentY + cy;
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.quadraticBezierTo(controlX, controlY, nx, ny);
          prevCtrlX = controlX;
          prevCtrlY = controlY;
          currentX = nx;
          currentY = ny;
          break;
        }
      case 'T':
        {
          final ex = nextNum();
          final ey = nextNum();
          final controlX = 2 * currentX - prevCtrlX;
          final controlY = 2 * currentY - prevCtrlY;
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.quadraticBezierTo(controlX, controlY, nx, ny);
          prevCtrlX = controlX;
          prevCtrlY = controlY;
          currentX = nx;
          currentY = ny;
          break;
        }
      case 'A':
        {
          final rx = nextNum();
          final ry = nextNum();
          final xAxisRotation = nextNum();
          final largeArcFlag = nextNum();
          final sweepFlag = nextNum();
          final ex = nextNum();
          final ey = nextNum();
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.arcToPoint(
            Offset(nx, ny),
            radius: Radius.elliptical(rx, ry),
            rotation: xAxisRotation,
            largeArc: largeArcFlag != 0,
            clockwise: sweepFlag != 0,
          );
          currentX = nx;
          currentY = ny;
          resetControl();
          break;
        }
      case 'Z':
        path.close();
        currentX = subpathX;
        currentY = subpathY;
        resetControl();
        break;
      default:
        // Unknown command: bail out to avoid desync.
        return path;
    }
  }

  return path;
}

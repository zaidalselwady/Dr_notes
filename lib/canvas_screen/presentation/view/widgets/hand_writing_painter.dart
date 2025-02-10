import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class HandwritingPainter extends CustomPainter {
  final List<MapEntry<Path, Paint>> paths;
  final Path currentPath;
  final bool isErasing;

  HandwritingPainter(this.paths, this.currentPath, this.isErasing);

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw grid lines (graph notebook style)
    _drawGrid(canvas, size);

    // Draw all paths
    for (final entry in paths) {
      canvas.drawPath(entry.key, entry.value);
    }

    // Draw the current path
    if (!isErasing) {
      Paint currentPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(currentPath, currentPaint);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    double spacing = 60.0; // Adjust for smaller or larger grids

    // Draw vertical lines
    // for (double x = 0; x <= size.width; x += spacing) {
    //   canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    // }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}


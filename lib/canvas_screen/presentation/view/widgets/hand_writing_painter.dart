import 'package:flutter/material.dart';

class HandwritingPainter extends CustomPainter {
  final List<MapEntry<Path, Paint>> paths;
  final Path currentPath;
  final bool isErasing;

  HandwritingPainter(this.paths, this.currentPath, this.isErasing);

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw all paths
    for (final entry in paths) {
      canvas.drawPath(entry.key, entry.value);
    }

    // Draw the current path
    if (!isErasing) {
      //Paint backgroundPaint = Paint()..color = Colors.white;
      Paint currentPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // canvas.drawRect(
      //     Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

      canvas.drawPath(currentPath, currentPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

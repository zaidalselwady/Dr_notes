import 'package:flutter/material.dart';

import '../canvas_screen.dart';

// class HandwritingPainter extends CustomPainter {
//   final List<MapEntry<Path, Paint>> paths;
//   final Path currentPath;
//   final bool isErasing;

//   HandwritingPainter(this.paths, this.currentPath, this.isErasing, Paint paint);

//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint backgroundPaint = Paint()..color = Colors.white;
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

//     // Draw grid lines (graph notebook style)
//     _drawGrid(canvas, size);

//     // Draw all paths
//     for (final entry in paths) {
//       canvas.drawPath(entry.key, entry.value);
//     }

//     // Draw the current path
//     if (!isErasing) {
//       Paint currentPaint = Paint()
//         ..color = Colors.black
//         ..strokeWidth = 5.0
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round;

//       canvas.drawPath(currentPath, currentPaint);
//     }
//   }

//   void _drawGrid(Canvas canvas, Size size) {
//     Paint gridPaint = Paint()
//       ..color = Colors.grey.shade300
//       ..strokeWidth = 1.0;

//     double spacing = 60.0; // Adjust for smaller or larger grids

//     // Draw vertical lines
//     // for (double x = 0; x <= size.width; x += spacing) {
//     //   canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
//     // }

//     // Draw horizontal lines
//     for (double y = 0; y <= size.height; y += spacing) {
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return true;
//   }
// }












// class HandwritingPainter extends CustomPainter {
//   final List<MapEntry<Path, Paint>> paths;
//   final Path currentPath;
//   final bool isErasing;
//   final List<StrokeModel>? strokes; // 👈 جديد

//   HandwritingPainter(
//     this.paths,
//     this.currentPath,
//     this.isErasing, Paint paint, {
//     this.strokes,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     // خلفية
//     Paint backgroundPaint = Paint()..color = Colors.white;
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

//     // خطوط أفقية خفيفة (اختياري)
//     _drawGrid(canvas, size);

//     // ✏️ أولاً: ارسم الـ strokes (المخزنة والمحملة من JSON)
//     if (strokes != null && strokes!.isNotEmpty) {
//       for (final stroke in strokes!) {
//         final paint = Paint()
//           ..color = stroke.color
//           ..strokeWidth = stroke.width
//           ..style = PaintingStyle.stroke
//           ..strokeCap = StrokeCap.round;

//         final path = Path();
//         if (stroke.points.isNotEmpty) {
//           path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
//           for (var point in stroke.points.skip(1)) {
//             path.lineTo(point.dx, point.dy);
//           }
//         }

//         canvas.drawPath(path, paint);
//       }
//     }

//     // ✏️ بعدها: ارسم الـ paths (اللي المستخدم يرسمها الآن)
//     for (final entry in paths) {
//       canvas.drawPath(entry.key, entry.value);
//     }

//     // ✏️ وأخيرًا: ارسم المسار الحالي (Current Path)
//     if (!isErasing) {
//       Paint currentPaint = Paint()
//         ..color = Colors.black
//         ..strokeWidth = 5.0
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round;
//       canvas.drawPath(currentPath, currentPaint);
//     }
//   }

//   void _drawGrid(Canvas canvas, Size size) {
//     Paint gridPaint = Paint()
//       ..color = Colors.grey.shade300
//       ..strokeWidth = 1.0;

//     double spacing = 60.0;
//     for (double y = 0; y <= size.height; y += spacing) {
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }





class HandwritingPainter extends CustomPainter {
  final List<StrokeModel> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final bool isErasing;

  HandwritingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    this.isErasing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // خلفية
    Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // خطوط أفقية خفيفة (اختياري)
    _drawGrid(canvas, size);

    // ✏️ ارسم الـ strokes (المخزنة والمحملة من JSON)
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (stroke.points.length > 1) {
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      }
    }

    // ✏️ ارسم الخط الحالي (Current Stroke)
    if (!isErasing && currentPoints.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (currentPoints.length > 1) {
        for (int i = 0; i < currentPoints.length - 1; i++) {
          canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
        }
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    double spacing = 60.0;
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
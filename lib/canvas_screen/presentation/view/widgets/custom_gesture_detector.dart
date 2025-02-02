// import 'package:flutter/material.dart';

// import 'hand_writing_painter.dart';

// class CustomGestureDetector extends StatefulWidget {
//   const CustomGestureDetector({
//     super.key,
//     required List<MapEntry<Path, Paint>> paths,
//     required Path currentPath,
//     required bool isErasing,
//   })  : paths = paths,
//         currentPath = currentPath,
//         isErasing = isErasing;

//   final List<MapEntry<Path, Paint>> paths;
//   final Path currentPath;
//   final bool isErasing;

//   @override
//   State<CustomGestureDetector> createState() => _CustomGestureDetectorState();
// }

// class _CustomGestureDetectorState extends State<CustomGestureDetector> {
//   late Path _currentPath;
//   @override
//   void initState() {
//     _currentPath = widget.currentPath;
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onPanStart: (details) {
//         setState(() {
//           if (!widget.isErasing) {
//             _currentPath = Path(); // Start new path for drawing
//             widget.currentPath
//                 .moveTo(details.localPosition.dx, details.localPosition.dy);
//           }
//         });
//       },
//       onPanUpdate: (details) {
//         setState(() {
//           if (widget.isErasing) {
//             _handleEraser(details.localPosition);
//           } else {
//             widget.currentPath
//                 .lineTo(details.localPosition.dx, details.localPosition.dy);
//           }
//         });
//       },
//       onPanEnd: (_) {
//         setState(() {
//           if (!widget.isErasing) {
//             widget.paths.add(
//                 MapEntry(widget.currentPath, _createPaint(Colors.black, 2.5)));
//           }
//           _currentPath = Path();
//         });
//       },
//       child: CustomPaint(
//         painter: HandwritingPainter(
//             widget.paths, widget.currentPath, widget.isErasing),
//         size: Size.infinite,
//       ),
//     );
//   }

//   Paint _createPaint(Color color, double strokeWidth) {
//     return Paint()
//       ..color = color
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = strokeWidth
//       ..style = PaintingStyle.stroke;
//   }

//   void _handleEraser(Offset position) {
//     // Remove paths intersecting with the eraser
//     widget.paths.removeWhere((entry) => entry.key.contains(position));
//   }
// }

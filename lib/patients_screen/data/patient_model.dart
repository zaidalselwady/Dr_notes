// class HandwritingScreen extends StatefulWidget {
//   const HandwritingScreen({super.key, required this.dataRepo});
//   final DataRepo dataRepo;
//   @override
//   _HandwritingScreenState createState() => _HandwritingScreenState();
// }
// class _HandwritingScreenState extends State<HandwritingScreen> {
//   final List<List<Offset>> _lines = []; // List of lines
//   final List<Offset> _currentLine = []; // Current line being drawn
//   bool _isErasing = false; // Indicates whether eraser mode is active
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Handwriting Screen'),
//         actions: [
//           IconButton(
//             icon: Icon(_isErasing ? Icons.brush : Icons.clear),
//             onPressed: () {
//               setState(() {
//                 _isErasing = !_isErasing; // Toggle eraser mode
//               });
//             },
//           ),
//         ],
//       ),
//       body: GestureDetector(
//         onPanUpdate: (details) {
//           setState(() {
//             if (_isErasing) {
//               _handleEraser(details.localPosition); // Handle eraser mode
//             } else {
//               _handleDrawing(details.localPosition); // Handle drawing mode
//             }
//           });
//         },
//         onPanEnd: (_) {
//           setState(() {
//             _lines.add(
//                 List.from(_currentLine)); // Add completed line to lines list
//             _currentLine.clear(); // Clear current line
//           });
//         },
//         child: CustomPaint(
//           painter: HandwritingPainter(_lines, _currentLine),
//           size: Size.infinite,
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           uploadPhoto("");
//         },
//         child: const Icon(Icons.upload),
//       ),
//     );
//   }
// // function to convert to String
//   Future<String> convertCanvasToB64() async {
//     final img = await rendered;
//     final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
//     final imgBase64 = base64.encode(pngBytes!.buffer.asUint8List());
//     return imgBase64;
//   }
//   // getter canvas to image
//   Future<ui.Image> get rendered {
//     var size = context.size;
//     ui.PictureRecorder recorder = ui.PictureRecorder();
//     Canvas canvas = Canvas(recorder);
//     final painter = HandwritingPainter(_lines, _currentLine);
//     painter.paint(canvas, size!);
//     return recorder
//         .endRecording()
//         .toImage(size.width.floor(), size.height.floor());
//   }
// Future<Uint8List> exportToImage() async {
//   final recorder = ui.PictureRecorder();
//   final canvas = Canvas(recorder);
//   final painter = HandwritingPainter(_lines, _currentLine);
//   painter.paint(canvas, const Size(800, 600)); // Adjust the size as needed
//   final picture = recorder.endRecording();
//   final img = await picture.toImage(800, 600); // Adjust the size as needed
//   final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
//   return byteData!.buffer.asUint8List();
// }
//   Future<void> uploadPhoto(String folderName) async {
//     try {
//       final base64Image = await convertCanvasToB64();
//       // Make SOAP request to upload the image
//       var result = await widget.dataRepo.fetchWithSoapRequest(
//           action: "WriteImageFile",
//           newName: folderName,
//           currentFolder: "",
//           filePath: "DrApp/p6/test.jpg",
//           imageBytes: base64Image);
//       result.fold((failure) {
//         print(failure.errorMsg);
//       }, (dMaster) async {
//         final document = xml.XmlDocument.parse(dMaster.body);
//         final resultElement =
//             document.findAllElements('WriteImageFileResult').first;
//         final responseString = resultElement.innerText;
//         print(responseString);
//       });
//     } catch (e) {
//       print('Error uploading photo: $e');
//     }
//   }
// Future<void> uploadPhoto1(String folderName) async {
//   var result = await widget.dataRepo
//       .fetchWithSoapRequest(action: "WriteImageFile", folderName: folderName,currentFolder:  "",filePath:"" ,imageBytes:"" );
//   result.fold((failure) {
//     print(failure.errorMsg);
//   }, (dMaster) async {
//     final document = xml.XmlDocument.parse(dMaster.body);
//     final resultElement =
//         document.findAllElements('IO_Create_FolderResult').first;
//     final jsonString = resultElement.innerText;
//     print(jsonString);
//   });
// }
//   void _handleDrawing(Offset position) {
//     _currentLine.add(position); // Add point to current line being drawn
//   }
//   void _handleEraser(Offset position) {
//     // Check if any point is within the eraser area
//     for (int i = 0; i < _lines.length; i++) {
//       if (_lines[i].any((point) => (point - position).distanceSquared <= 100)) {
//         // Adjust eraser size as needed
//         _lines
//             .removeAt(i); // Remove line if any point intersects with the eraser
//         break; // Stop after removing one line to ensure only one line is erased
//       }
//     }
//   }
// }
// class HandwritingPainter extends CustomPainter {
//   final List<List<Offset>> lines;
//   final List<Offset> currentLine;
//   HandwritingPainter(this.lines, this.currentLine);
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = 5.0;
//     // Draw completed lines
//     for (final line in lines) {
//       for (int i = 0; i < line.length - 1; i++) {
//         canvas.drawLine(line[i], line[i + 1], paint);
//       }
//     }
//     // Draw current line being drawn
//     for (int i = 0; i < currentLine.length - 1; i++) {
//       canvas.drawLine(currentLine[i], currentLine[i + 1], paint);
//     }
//   }
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return true;
//   }
// }

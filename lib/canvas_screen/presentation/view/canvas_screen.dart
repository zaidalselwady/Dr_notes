// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hand_write_notes/core/date_format_service.dart';
// import 'package:hand_write_notes/patient_visits_screen/data/image_model.dart';
// import 'package:hand_write_notes/patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
// import 'package:hand_write_notes/upload_files_cubit/cubit/upload_files_cubit.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import '../../../convert_canvas_B64_cubit/cubit/convert_canvas_b64_cubit.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../information_screen/presentation/view/info.dart';
// import 'widgets/hand_writing_painter.dart';
// import 'widgets/pen_eraser.dart';

// class HandwritingScreen extends StatefulWidget {
//   const HandwritingScreen(
//       {super.key, required this.patientId, this.imageModel});
//   final int patientId;
//   final ImageModel? imageModel;

//   @override
//   _HandwritingScreenState createState() => _HandwritingScreenState();
// }

// class _HandwritingScreenState extends State<HandwritingScreen> {
//   // Drawing state
//   final List<MapEntry<Path, Paint>> _paths = [];
//   final List<List<MapEntry<Path, Paint>>> _undoStack = [];
//   final List<List<MapEntry<Path, Paint>>> _redoStack = [];
//   List<StrokeModel> _strokes = [];
//   List<Offset> _currentStrokePoints = [];
//   Path _currentPath = Path();
//   bool _isErasing = false;

//   // Drawing customization
//   Color _currentColor = Colors.black;
//   double _currentStrokeWidth = 2.5;

//   // Settings and date management
//   String _dateFormat = "dd-MM-yyyy";
//   DateTime _selectedDateTime = DateTime.now();

//   TextEditingController dateController = TextEditingController();

//   // Constants for performance optimization
//   static const int _maxPaths = 1000;
//   static const int _pathCleanupBatch = 100;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.imageModel != null &&
//         widget.imageModel!.strokesJson != null &&
//         widget.imageModel!.strokesJson!.isNotEmpty) {
//       // حمّل الـ strokes من JSON
//       _loadStrokesFromJson(widget.imageModel!.strokesJson!);
//     }
//   }

//   void _loadStrokesFromJson(String base64Str) {
//     try {
//       // 1️⃣ أولاً حول Base64 لـ UTF8 string
//       final jsonStr = utf8.decode(base64Decode(base64Str));

//       final Map<String, dynamic> decodedMap = jsonDecode(jsonStr);
//       final List strokesList = decodedMap['strokes'];

//       setState(() {
//         _strokes = strokesList.map((e) => StrokeModel.fromJson(e)).toList();
//       });
//     } catch (e) {
//       debugPrint('Failed to load strokes: $e');
//     }
//   }

//   String get _displayDate {
//     return DateService.format(_selectedDateTime, _dateFormat);
//   }

//   void _saveStateForUndo() {
//     _undoStack.add(List<MapEntry<Path, Paint>>.from(_paths));
//     _redoStack.clear(); // Clear redo stack when new action is performed

//     // Limit undo stack size for memory management
//     if (_undoStack.length > 20) {
//       _undoStack.removeAt(0);
//     }
//   }

//   void _undo() {
//     if (_undoStack.isNotEmpty) {
//       _redoStack.add(List<MapEntry<Path, Paint>>.from(_paths));
//       setState(() {
//         _paths.clear();
//         if (_undoStack.isNotEmpty) {
//           _paths.addAll(_undoStack.removeLast());
//         }
//       });
//     }
//   }

//   void _redo() {
//     if (_redoStack.isNotEmpty) {
//       _undoStack.add(List<MapEntry<Path, Paint>>.from(_paths));
//       setState(() {
//         _paths.clear();
//         _paths.addAll(_redoStack.removeLast());
//       });
//     }
//   }

//   void _clearCanvas() {
//     if (_paths.isNotEmpty) {
//       _saveStateForUndo();
//       setState(() {
//         _paths.clear();
//       });
//     }
//   }

//   void _optimizePathsIfNeeded() {
//     if (_paths.length > _maxPaths) {
//       final pathsToRemove = _paths.length - _maxPaths + _pathCleanupBatch;
//       _paths.removeRange(0, pathsToRemove);
//     }
//   }

//   Future<void> _selectDate() async {
//     // final pickedDate = await showDatePicker(
//     //     context: context,
//     //     initialDate: _selectedDateTime,
//     //     firstDate: DateTime(2000),
//     //     lastDate: DateTime.now(),
//     //     locale: const Locale('en', 'GB'),
//     //     initialEntryMode: DatePickerEntryMode.input);
//     dateController.text = _displayDate;
//     final pickedDate = await showAdaptiveDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text('Select Date'),
//             content: TextFormField(
//               controller: dateController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter date',
//                 hintText: 'dd-MM-yyyy',
//               ),
//               keyboardType: TextInputType.datetime,
//               inputFormatters: [
//                 FilteringTextInputFormatter.digitsOnly,
//                 LengthLimitingTextInputFormatter(8), // ddMMyyyy
//                 FlexibleDateInputFormatter(),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(dateController.text);
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           );
//         });

//     DateTime? parsedDate = DateFormat(_dateFormat).tryParseStrict(pickedDate);
//     if (parsedDate != null) {
//       setState(() {
//         _selectedDateTime = DateTime(
//           parsedDate.year,
//           parsedDate.month,
//           parsedDate.day,
//           _selectedDateTime.hour,
//           _selectedDateTime.minute,
//           _selectedDateTime.second,
//         );
//       });
//     } else if (pickedDate != null && pickedDate.isNotEmpty) {
//       // Show error if date is invalid
//       _showErrorMessage('Invalid date format. Please use dd-MM-yyyy.');
//     }
//   }

//   Future<void> _captureAndUploadImage() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? photo = await picker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 85, // Improved quality
//       );

//       if (photo != null) {
//         final File imageFile = File(photo.path);
//         final Uint8List imageBytes = await imageFile.readAsBytes();
//         final String base64Image = base64Encode(imageBytes);

//         // Keep the selected date for photo upload - only update time
//         final uploadDateTime = DateTime(
//           _selectedDateTime.year,
//           _selectedDateTime.month,
//           _selectedDateTime.day,
//           DateTime.now().hour,
//           DateTime.now().minute,
//           DateTime.now().second,
//         );

//         final imageName =
//             DateService.format(uploadDateTime, "$_dateFormat kk-mm-ss");

//         final uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
//         uploadCubit.uploadPhoto(
//           "",
//           base64Image,
//           "$imageName.png",
//           "P${widget.patientId}",
//         );
//       }
//     } catch (e) {
//       _showErrorMessage('Failed to capture image: ${e.toString()}');
//     }
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   Widget _buildToolbar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Undo button
//           IconButton(
//             onPressed: _undoStack.isEmpty ? null : _undo,
//             icon: const Icon(Icons.undo),
//             tooltip: 'Undo',
//           ),

//           // Redo button
//           IconButton(
//             onPressed: _redoStack.isEmpty ? null : _redo,
//             icon: const Icon(Icons.redo),
//             tooltip: 'Redo',
//           ),

//           const SizedBox(width: 16),

//           // Stroke width slider
//           const Text('Size:'),
//           const SizedBox(width: 8),
//           SizedBox(
//             width: 100,
//             child: Slider(
//               value: _currentStrokeWidth,
//               min: 1.0,
//               max: 10.0,
//               divisions: 9,
//               onChanged: (value) {
//                 setState(() {
//                   _currentStrokeWidth = value;
//                 });
//               },
//             ),
//           ),

//           const Spacer(),

//           // Clear canvas button
//           IconButton(
//             onPressed: _paths.isEmpty ? null : _clearCanvas,
//             icon: const Icon(Icons.clear_all),
//             tooltip: 'Clear All',
//             color: Colors.red,
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final convertCubit = BlocProvider.of<ConvertCanvasB64Cubit>(context);
//     final uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
//     final uploadVisitsCubit =
//         BlocProvider.of<UploadPatientVisitsCubit>(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         title: Text('Patient ${widget.patientId} Notes'),
//         actions: [
//           // Date selector button
//           TextButton.icon(
//             onPressed: _selectDate,
//             icon: const Icon(Icons.calendar_today, size: 16),
//             label: Text(_displayDate),
//             style: TextButton.styleFrom(
//               foregroundColor: Theme.of(context).primaryColor,
//             ),
//           ),

//           // Camera button
//           IconButton(
//             onPressed: _captureAndUploadImage,
//             icon: const Icon(Icons.camera_alt),
//             tooltip: 'Take Photo',
//           ),

//           // Pen/Eraser toggle
//           PenAndEraser(
//             isErasing: _isErasing,
//             onToggle: () {
//               setState(() {
//                 _isErasing = !_isErasing;
//               });
//             },
//           ),
//         ],
//       ),
//       body: BlocConsumer<UploadFilesCubit, UploadFilesState>(
//         listener: (context, state) {
//           if (state is UploadFilesSuccess) {
//             _showSuccessMessage('Upload Successful: ${state.responseString}');
//             Future.delayed(const Duration(seconds: 1), () {
//               Navigator.of(context).pop(true);
//             });
//           } else if (state is UploadFilesError) {
//             _showErrorMessage('Upload Error: ${state.errorMessage}');
//           }
//         },
//         builder: (context, state) {
//           if (state is CanvasLoading ||
//               state is UploadingFiles ||
//               state is UploadingPatientVisits) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }

//           return Column(
//             children: [
//               _buildToolbar(),
//               Expanded(
//                 child: GestureDetector(
//                   onPanStart: (details) {
//                     if (!_isErasing) {
//                       _saveStateForUndo();
//                       setState(() {
//                         _currentPath = Path();
//                         _currentPath.moveTo(
//                           details.localPosition.dx,
//                           details.localPosition.dy,
//                         );
//                       });
//                       _currentStrokePoints = [details.localPosition];
//                     }
//                   },
//                   onPanUpdate: (details) {
//                     setState(() {
//                       if (_isErasing) {
//                         _handleEraser(details.localPosition);
//                       } else {
//                         _currentPath.lineTo(
//                           details.localPosition.dx,
//                           details.localPosition.dy,
//                         );
//                         _currentStrokePoints.add(details.localPosition);
//                       }
//                     });
//                   },
//                   onPanEnd: (_) {
//                     if (!_isErasing && _currentPath != Path()) {
//                       setState(() {
//                         _paths.add(
//                           MapEntry(
//                             _currentPath,
//                             _createPaint(_currentColor, _currentStrokeWidth),
//                           ),
//                         );
//                         _currentPath = Path();
//                         _optimizePathsIfNeeded();
//                       });
//                       if (_currentStrokePoints.isNotEmpty) {
//                         _strokes.add(
//                           StrokeModel(
//                             points: List<Offset>.from(_currentStrokePoints),
//                             color: _currentColor,
//                             width: _currentStrokeWidth,
//                           ),
//                         );
//                         _currentStrokePoints.clear();
//                       }
//                     }
//                   },
//                   child: Container(
//                     width: double.infinity,
//                     height: double.infinity,
//                     color: Colors.white,
//                     child: CustomPaint(
//                       painter: HandwritingPainter(
//                         strokes: _strokes,
//                         _paths,
//                         _currentPath,
//                         _isErasing,
//                         Paint()
//                           ..color = _currentColor
//                           ..strokeCap = StrokeCap.round
//                           ..strokeWidth = _currentStrokeWidth
//                           ..style = PaintingStyle.stroke,
//                       ),
//                       size: Size.infinite,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: _paths.isNotEmpty
//           ? FloatingActionButton.extended(
//               onPressed: () async {
//                 String strokesJson = jsonEncode({
//                   "strokes": _strokes.map((s) => s.toJson()).toList(),
//                 });
//                 // Keep the selected date, only update time for upload
//                 final uploadDateTime = DateTime(
//                   _selectedDateTime.year,
//                   _selectedDateTime.month,
//                   _selectedDateTime.day,
//                   DateTime.now().hour,
//                   DateTime.now().minute,
//                   DateTime.now().second,
//                 );

//                 final imageName = widget.imageModel != null
//                     ? widget.imageModel!.imgName.replaceAll(".json", "")
//                     : DateService.format(
//                         uploadDateTime, "$_dateFormat kk-mm-ss");

//                 await uploadCubit.uploadPhoto(
//                   "",
//                   strokesJson,
//                   "$imageName.json",
//                   "P${widget.patientId}",
//                 );
//               },
//               icon: const Icon(Icons.upload),
//               label: const Text('Upload'),
//             )
//           : FloatingActionButton(
//               onPressed: () {
//                 _showErrorMessage('No notes available to upload');
//               },
//               backgroundColor: Colors.grey,
//               child: const Icon(Icons.upload),
//             ),
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
//     const double eraserRadius = 20.0;
//     bool erased = false;
//     _paths.removeWhere((entry) {
//       final shouldRemove =
//           _isPathNearPosition(entry.key, position, eraserRadius);
//       if (shouldRemove) erased = true;
//       return shouldRemove;
//     });
//     if (erased) setState(() {});
//   }

//   bool _isPathNearPosition(Path path, Offset position, double radius) {
//     // Simple approximation - check if path contains point within radius
//     final bounds = path.getBounds();
//     return bounds.contains(position) ||
//         (bounds.center - position).distance < radius;
//   }
// }

// class StrokeModel {
//   final List<Offset> points;
//   final Color color;
//   final double width;

//   StrokeModel({required this.points, required this.color, required this.width});

//   Map<String, dynamic> toJson() {
//     return {
//       "color": "#${color.value.toRadixString(16).padLeft(8, '0')}",
//       "width": width,
//       "points": points.map((p) => {"x": p.dx, "y": p.dy}).toList(),
//     };
//   }

//   static StrokeModel fromJson(Map<String, dynamic> json) {
//     return StrokeModel(
//       color: Color(int.parse(json["color"].substring(1), radix: 16)),
//       width: (json["width"] as num).toDouble(),
//       points: (json["points"] as List)
//           .map((p) => Offset(p["x"].toDouble(), p["y"].toDouble()))
//           .toList(),
//     );
//   }
// }

// // Keep your existing RecognizedText widget
// class RecognizedText extends StatelessWidget {
//   const RecognizedText({super.key, required this.base64Image});
//   final String base64Image;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Recognized Text')),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Center(
//             child: Text(
//               base64Image,
//               style: const TextStyle(fontSize: 20),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

//NUMBER 3

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_write_notes/core/date_format_service.dart';
import 'package:hand_write_notes/patient_visits_screen/data/image_model.dart';
import 'package:hand_write_notes/patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
import 'package:hand_write_notes/upload_files_cubit/cubit/upload_files_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../convert_canvas_B64_cubit/cubit/convert_canvas_b64_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../information_screen/presentation/view/info.dart';
import 'widgets/hand_writing_painter.dart';
import 'widgets/pen_eraser.dart';

class HandwritingScreen extends StatefulWidget {
  const HandwritingScreen(
      {super.key, required this.patientId, this.imageModel});
  final int patientId;
  final ImageModel? imageModel;

  @override
  _HandwritingScreenState createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends State<HandwritingScreen> {
  // Drawing state
  List<StrokeModel> _strokes = [];
  final List<List<StrokeModel>> _undoStack = [];
  final List<List<StrokeModel>> _redoStack = [];
  List<Offset> _currentWorldPoints = [];
  bool _isErasing = false;
  Offset _offset = Offset.zero;
  final Map<int, Offset> _activePointers = <int, Offset>{};
  int? _drawingPointer;
  bool _panMode = false;

  // Drawing customization
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.5;

  // Settings and date management
  String _dateFormat = "dd-MM-yyyy";
  DateTime _selectedDateTime = DateTime.now();

  TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.imageModel != null &&
        widget.imageModel!.strokesJson != null &&
        widget.imageModel!.strokesJson!.isNotEmpty) {
      // حمّل الـ strokes من JSON
      _loadStrokesFromJson(widget.imageModel!.strokesJson!);
    }
  }

  @override
  void dispose() {
    _activePointers.clear();
    super.dispose();
  }

  Offset _localToWorld(Offset local) {
    return local - _offset;
  }

  void _handlePointerUp(int pointer) {
    final bool wasDrawing = pointer == _drawingPointer;
    _activePointers.remove(pointer);
    if (wasDrawing) {
      if (!_isErasing && _currentWorldPoints.isNotEmpty) {
        setState(() {
          _strokes.add(
            StrokeModel(
              points: List<Offset>.from(_currentWorldPoints),
              color: _currentColor,
              width: _currentStrokeWidth,
            ),
          );
          _currentWorldPoints.clear();
        });
      }
      _drawingPointer = null;
    }
    if (_activePointers.isEmpty) {
      _panMode = false;
    }
  }

  void _loadStrokesFromJson(String base64Str) {
    try {
      // 1️⃣ أولاً حول Base64 لـ UTF8 string
      final jsonStr = utf8.decode(base64Decode(base64Str));

      final Map<String, dynamic> decodedMap = jsonDecode(jsonStr);
      final List strokesList = decodedMap['strokes'];

      setState(() {
        _strokes = strokesList.map((e) => StrokeModel.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint('Failed to load strokes: $e');
    }
  }

  String get _displayDate {
    return DateService.format(_selectedDateTime, _dateFormat);
  }

  void _saveStateForUndo() {
    _undoStack.add(List<StrokeModel>.from(_strokes));
    _redoStack.clear(); // Clear redo stack when new action is performed

    // Limit undo stack size for memory management
    if (_undoStack.length > 20) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(List<StrokeModel>.from(_strokes));
      setState(() {
        _strokes = _undoStack.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(List<StrokeModel>.from(_strokes));
      setState(() {
        _strokes = _redoStack.removeLast();
      });
    }
  }

  void _clearCanvas() {
    if (_strokes.isNotEmpty) {
      _saveStateForUndo();
      setState(() {
        _strokes.clear();
      });
    }
  }

  Future<void> _selectDate() async {
    dateController.text = _displayDate;
    final pickedDate = await showAdaptiveDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Date'),
            content: TextFormField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Enter date',
                hintText: 'dd-MM-yyyy',
              ),
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8), // ddMMyyyy
                FlexibleDateInputFormatter(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(dateController.text);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });

    DateTime? parsedDate = DateFormat(_dateFormat).tryParseStrict(pickedDate);
    if (parsedDate != null) {
      setState(() {
        _selectedDateTime = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
          _selectedDateTime.second,
        );
      });
    } else if (pickedDate != null && pickedDate.isNotEmpty) {
      // Show error if date is invalid
      _showErrorMessage('Invalid date format. Please use dd-MM-yyyy.');
    }
  }

  Future<void> _captureAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Improved quality
      );

      if (photo != null) {
        final File imageFile = File(photo.path);
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final String base64Image = base64Encode(imageBytes);

        // Keep the selected date for photo upload - only update time
        final uploadDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          DateTime.now().hour,
          DateTime.now().minute,
          DateTime.now().second,
        );

        final imageName =
            DateService.format(uploadDateTime, "$_dateFormat kk-mm-ss");

        final uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
        uploadCubit.uploadPhoto(
          "",
          base64Image,
          "$imageName.png",
          "P${widget.patientId}",
        );
      }
    } catch (e) {
      _showErrorMessage('Failed to capture image: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Undo button
          IconButton(
            onPressed: _undoStack.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
          ),

          // Redo button
          IconButton(
            onPressed: _redoStack.isEmpty ? null : _redo,
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
          ),

          const SizedBox(width: 16),

          // Stroke width slider
          const Text('Size:'),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Slider(
              value: _currentStrokeWidth,
              min: 1.0,
              max: 10.0,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _currentStrokeWidth = value;
                });
              },
            ),
          ),

          const Spacer(),

          // Clear canvas button
          IconButton(
            onPressed: _strokes.isEmpty ? null : _clearCanvas,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
    final uploadVisitsCubit =
        BlocProvider.of<UploadPatientVisitsCubit>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text('Patient ${widget.patientId} Notes'),
        actions: [
          // Date selector button
          TextButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_displayDate),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),

          // Camera button
          IconButton(
            onPressed: _captureAndUploadImage,
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Take Photo',
          ),

          // Pen/Eraser toggle
          PenAndEraser(
            isErasing: _isErasing,
            onToggle: () {
              setState(() {
                _isErasing = !_isErasing;
              });
            },
          ),
        ],
      ),
      body: BlocConsumer<UploadFilesCubit, UploadFilesState>(
        listener: (context, state) {
          if (state is UploadFilesSuccess) {
            _showSuccessMessage('Upload Successful: ${state.responseString}');

            Navigator.of(context).pop(true);
          } else if (state is UploadFilesError) {
            _showErrorMessage('Upload Error: ${state.errorMessage}');
          }
        },
        builder: (context, state) {
          if (state is CanvasLoading ||
              state is UploadingFiles ||
              state is UploadingPatientVisits) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (PointerDownEvent event) {
                    final int oldLength = _activePointers.length;
                    _activePointers[event.pointer] = event.localPosition;
                    if (oldLength == 1 && _activePointers.length == 2) {
                      _panMode = true;
                    }
                    if (_activePointers.length == 1) {
                      _drawingPointer = event.pointer;
                      _saveStateForUndo();
                      if (!_isErasing) {
                        final worldPos = _localToWorld(event.localPosition);
                        setState(() {
                          _currentWorldPoints = [worldPos];
                        });
                      }
                    }
                  },
                  onPointerMove: (PointerMoveEvent event) {
                    if (!_activePointers.containsKey(event.pointer)) return;
                    final oldPosition = _activePointers[event.pointer]!;
                    final int currentLength = _activePointers.length;
                    if (currentLength > 1) {
                      // Pan
                      double oldSumX = 0, oldSumY = 0;
                      for (final pos in _activePointers.values) {
                        oldSumX += pos.dx;
                        oldSumY += pos.dy;
                      }
                      final int len = currentLength;
                      final Offset oldCenter = Offset(oldSumX / len, oldSumY / len);
                      final double dx = event.localPosition.dx - oldPosition.dx;
                      final double dy = event.localPosition.dy - oldPosition.dy;
                      final double newSumX = oldSumX + dx;
                      final double newSumY = oldSumY + dy;
                      final Offset newCenter = Offset(newSumX / len, newSumY / len);
                      final Offset delta = newCenter - oldCenter;
                      _activePointers[event.pointer] = event.localPosition;
                      setState(() {
                        _offset += delta;
                      });
                    } else if (currentLength == 1 && !_panMode) {
                      // Draw or erase
                      final worldPos = _localToWorld(event.localPosition);
                      setState(() {
                        if (_isErasing) {
                          _handleEraser(worldPos);
                        } else {
                          _currentWorldPoints.add(worldPos);
                        }
                      });
                      _activePointers[event.pointer] = event.localPosition;
                    }
                  },
                  onPointerUp: (PointerUpEvent event) {
                    _handlePointerUp(event.pointer);
                  },
                  onPointerCancel: (PointerCancelEvent event) {
                    _handlePointerUp(event.pointer);
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white,
                    child: CustomPaint(
                      painter: HandwritingPainter(
                        strokes: _strokes,
                        currentPoints: _currentWorldPoints,
                        currentColor: _currentColor,
                        currentWidth: _currentStrokeWidth,
                        isErasing: _isErasing,
                        offset: _offset,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _strokes.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                String strokesJson = jsonEncode({
                  "strokes": _strokes.map((s) => s.toJson()).toList(),
                });
                // Keep the selected date, only update time for upload
                final uploadDateTime = DateTime(
                  _selectedDateTime.year,
                  _selectedDateTime.month,
                  _selectedDateTime.day,
                  DateTime.now().hour,
                  DateTime.now().minute,
                  DateTime.now().second,
                );

                final imageName = widget.imageModel != null
                    ? widget.imageModel!.imgName.replaceAll(".json", "")
                    : DateService.format(
                        uploadDateTime, "$_dateFormat kk-mm-ss");

                await uploadCubit.uploadPhoto(
                  "",
                  strokesJson,
                  "$imageName.json",
                  "P${widget.patientId}",
                );
              },
              icon: const Icon(Icons.upload),
              label: const Text('Upload'),
            )
          : FloatingActionButton(
              onPressed: () {
                _showErrorMessage('No notes available to upload');
              },
              backgroundColor: Colors.grey,
              child: const Icon(Icons.upload),
            ),
    );
  }

  void _handleEraser(Offset worldPosition) {
    const double eraserRadius = 20.0;
    _strokes.removeWhere((stroke) => stroke.points
        .any((point) => (point - worldPosition).distance <= eraserRadius));
  }
}

class StrokeModel {
  final List<Offset> points;
  final Color color;
  final double width;

  StrokeModel({required this.points, required this.color, required this.width});

  Map<String, dynamic> toJson() {
    return {
      "color": "#${color.value.toRadixString(16).padLeft(8, '0')}",
      "width": width,
      "points": points.map((p) => {"x": p.dx, "y": p.dy}).toList(),
    };
  }

  static StrokeModel fromJson(Map<String, dynamic> json) {
    return StrokeModel(
      color: Color(int.parse(json["color"].substring(1), radix: 16)),
      width: (json["width"] as num).toDouble(),
      points: (json["points"] as List)
          .map((p) => Offset(p["x"].toDouble(), p["y"].toDouble()))
          .toList(),
    );
  }
}

class HandwritingPainter extends CustomPainter {
  final List<StrokeModel> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final bool isErasing;
  final Offset offset;

  HandwritingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    this.isErasing = false,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // خلفية
    Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

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
          final Offset p1 = stroke.points[i] + offset;
          final Offset p2 = stroke.points[i + 1] + offset;
          canvas.drawLine(p1, p2, paint);
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
          final Offset p1 = currentPoints[i] + offset;
          final Offset p2 = currentPoints[i + 1] + offset;
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    const double spacing = 60.0;
    final double minWorldY = -offset.dy;
    final double maxWorldY = size.height - offset.dy;
    final double firstLineY = (minWorldY / spacing).ceilToDouble() * spacing;
    double worldY = firstLineY;
    while (worldY <= maxWorldY) {
      final double screenY = worldY + offset.dy;
      canvas.drawLine(
        Offset(0, screenY),
        Offset(size.width, screenY),
        gridPaint,
      );
      worldY += spacing;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}







//NUMBER 4

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math' as math;
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
// import 'package:hand_write_notes/core/date_format_service.dart';
// import 'package:hand_write_notes/patient_visits_screen/data/image_model.dart';
// import 'package:hand_write_notes/patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
// import 'package:hand_write_notes/upload_files_cubit/cubit/upload_files_cubit.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import '../../../convert_canvas_B64_cubit/cubit/convert_canvas_b64_cubit.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../information_screen/presentation/view/info.dart';
// import 'widgets/hand_writing_painter.dart';
// import 'widgets/pen_eraser.dart';

// class HandwritingScreen extends StatefulWidget {
//   const HandwritingScreen(
//       {super.key, required this.patientId, this.imageModel});
//   final int patientId;
//   final ImageModel? imageModel;

//   @override
//   _HandwritingScreenState createState() => _HandwritingScreenState();
// }

// class _HandwritingScreenState extends State<HandwritingScreen> {
//   // Drawing state
//   List<StrokeModel> _strokes = [];
//   final List<List<StrokeModel>> _undoStack = [];
//   final List<List<StrokeModel>> _redoStack = [];
//   List<Offset> _currentWorldPoints = [];
//   bool _isErasing = false;
//   Offset _offset = Offset.zero;
//   double _scale = 1.0;
//   double _initialScale = 1.0;
//   final GlobalKey _canvasKey = GlobalKey();
//   Timer? _zoomTimer;
//   bool _showZoom = false;

//   // Drawing customization
//   Color _currentColor = Colors.black;
//   double _currentStrokeWidth = 2.5;

//   // Settings and date management
//   String _dateFormat = "dd-MM-yyyy";
//   DateTime _selectedDateTime = DateTime.now();

//   TextEditingController dateController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.imageModel != null &&
//         widget.imageModel!.strokesJson != null &&
//         widget.imageModel!.strokesJson!.isNotEmpty) {
//       // حمّل الـ strokes من JSON
//       _loadStrokesFromJson(widget.imageModel!.strokesJson!);
//     }
//   }

//   @override
//   void dispose() {
//     _zoomTimer?.cancel();
//     super.dispose();
//   }

//   Offset _localToWorld(Offset localPosition) {
//     final RenderBox? box =
//         _canvasKey.currentContext?.findRenderObject() as RenderBox?;
//     if (box == null) return localPosition;
//     final Size size = box.size;
//     final Offset center = Offset(size.width / 2, size.height / 2);
//     Offset temp = localPosition + center;
//     temp = temp / _scale;
//     temp = temp - _offset;
//     return temp - center;
//   }

//   void _showZoomIndicator() {
//     setState(() {
//       _showZoom = true;
//     });
//     _zoomTimer?.cancel();
//     _zoomTimer = Timer(const Duration(seconds: 2), () {
//       if (mounted) {
//         setState(() {
//           _showZoom = false;
//         });
//       }
//     });
//   }

//   void _loadStrokesFromJson(String base64Str) {
//     try {
//       // 1️⃣ أولاً حول Base64 لـ UTF8 string
//       final jsonStr = utf8.decode(base64Decode(base64Str));

//       final Map<String, dynamic> decodedMap = jsonDecode(jsonStr);
//       final List strokesList = decodedMap['strokes'];

//       setState(() {
//         _strokes = strokesList.map((e) => StrokeModel.fromJson(e)).toList();
//       });
//     } catch (e) {
//       debugPrint('Failed to load strokes: $e');
//     }
//   }

//   String get _displayDate {
//     return DateService.format(_selectedDateTime, _dateFormat);
//   }

//   void _saveStateForUndo() {
//     _undoStack.add(List<StrokeModel>.from(_strokes));
//     _redoStack.clear(); // Clear redo stack when new action is performed

//     // Limit undo stack size for memory management
//     if (_undoStack.length > 20) {
//       _undoStack.removeAt(0);
//     }
//   }

//   void _undo() {
//     if (_undoStack.isNotEmpty) {
//       _redoStack.add(List<StrokeModel>.from(_strokes));
//       setState(() {
//         _strokes = _undoStack.removeLast();
//       });
//     }
//   }

//   void _redo() {
//     if (_redoStack.isNotEmpty) {
//       _undoStack.add(List<StrokeModel>.from(_strokes));
//       setState(() {
//         _strokes = _redoStack.removeLast();
//       });
//     }
//   }

//   void _clearCanvas() {
//     if (_strokes.isNotEmpty) {
//       _saveStateForUndo();
//       setState(() {
//         _strokes.clear();
//       });
//     }
//   }

//   Future<void> _selectDate() async {
//     dateController.text = _displayDate;
//     final pickedDate = await showAdaptiveDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text('Select Date'),
//             content: TextFormField(
//               controller: dateController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter date',
//                 hintText: 'dd-MM-yyyy',
//               ),
//               keyboardType: TextInputType.datetime,
//               inputFormatters: [
//                 FilteringTextInputFormatter.digitsOnly,
//                 LengthLimitingTextInputFormatter(8), // ddMMyyyy
//                 FlexibleDateInputFormatter(),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(dateController.text);
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           );
//         });

//     DateTime? parsedDate = DateFormat(_dateFormat).tryParseStrict(pickedDate);
//     if (parsedDate != null) {
//       setState(() {
//         _selectedDateTime = DateTime(
//           parsedDate.year,
//           parsedDate.month,
//           parsedDate.day,
//           _selectedDateTime.hour,
//           _selectedDateTime.minute,
//           _selectedDateTime.second,
//         );
//       });
//     } else if (pickedDate != null && pickedDate.isNotEmpty) {
//       // Show error if date is invalid
//       _showErrorMessage('Invalid date format. Please use dd-MM-yyyy.');
//     }
//   }

//   Future<void> _captureAndUploadImage() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? photo = await picker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 85, // Improved quality
//       );

//       if (photo != null) {
//         final File imageFile = File(photo.path);
//         final Uint8List imageBytes = await imageFile.readAsBytes();
//         final String base64Image = base64Encode(imageBytes);

//         // Keep the selected date for photo upload - only update time
//         final uploadDateTime = DateTime(
//           _selectedDateTime.year,
//           _selectedDateTime.month,
//           _selectedDateTime.day,
//           DateTime.now().hour,
//           DateTime.now().minute,
//           DateTime.now().second,
//         );

//         final imageName =
//             DateService.format(uploadDateTime, "$_dateFormat kk-mm-ss");

//         final uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
//         uploadCubit.uploadPhoto(
//           "",
//           base64Image,
//           "$imageName.png",
//           "P${widget.patientId}",
//         );
//       }
//     } catch (e) {
//       _showErrorMessage('Failed to capture image: ${e.toString()}');
//     }
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   Widget _buildToolbar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Undo button
//           IconButton(
//             onPressed: _undoStack.isEmpty ? null : _undo,
//             icon: const Icon(Icons.undo),
//             tooltip: 'Undo',
//           ),

//           // Redo button
//           IconButton(
//             onPressed: _redoStack.isEmpty ? null : _redo,
//             icon: const Icon(Icons.redo),
//             tooltip: 'Redo',
//           ),

//           const SizedBox(width: 16),

//           // Stroke width slider
//           const Text('Size:'),
//           const SizedBox(width: 8),
//           SizedBox(
//             width: 100,
//             child: Slider(
//               value: _currentStrokeWidth,
//               min: 1.0,
//               max: 10.0,
//               divisions: 9,
//               onChanged: (value) {
//                 setState(() {
//                   _currentStrokeWidth = value;
//                 });
//               },
//             ),
//           ),

//           const Spacer(),

//           // Clear canvas button
//           IconButton(
//             onPressed: _strokes.isEmpty ? null : _clearCanvas,
//             icon: const Icon(Icons.clear_all),
//             tooltip: 'Clear All',
//             color: Colors.red,
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
//     final uploadVisitsCubit =
//         BlocProvider.of<UploadPatientVisitsCubit>(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         title: Text('Patient ${widget.patientId} Notes'),
//         actions: [
//           // Date selector button
//           TextButton.icon(
//             onPressed: _selectDate,
//             icon: const Icon(Icons.calendar_today, size: 16),
//             label: Text(_displayDate),
//             style: TextButton.styleFrom(
//               foregroundColor: Theme.of(context).primaryColor,
//             ),
//           ),

//           // Camera button
//           IconButton(
//             onPressed: _captureAndUploadImage,
//             icon: const Icon(Icons.camera_alt),
//             tooltip: 'Take Photo',
//           ),

//           // Pen/Eraser toggle
//           PenAndEraser(
//             isErasing: _isErasing,
//             onToggle: () {
//               setState(() {
//                 _isErasing = !_isErasing;
//               });
//             },
//           ),
//         ],
//       ),
//       body: BlocConsumer<UploadFilesCubit, UploadFilesState>(
//         listener: (context, state) {
//           if (state is UploadFilesSuccess) {
//             _showSuccessMessage('Upload Successful: ${state.responseString}');

//             Navigator.of(context).pop(true);
//           } else if (state is UploadFilesError) {
//             _showErrorMessage('Upload Error: ${state.errorMessage}');
//           }
//         },
//         builder: (context, state) {
//           if (state is CanvasLoading ||
//               state is UploadingFiles ||
//               state is UploadingPatientVisits) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }

//           return Column(
//             children: [
//               _buildToolbar(),
//               Expanded(
//                 child: Stack(
//                   children: [
//                     // Replace your existing GestureDetector with this implementation
//                     GestureDetector(
//                       onScaleStart: (details) {
//                         // Check if this is a drawing action (single finger) or zoom/pan (multi-finger)
//                         if (details.pointerCount == 1 && !_isErasing) {
//                           // Drawing start
//                           _saveStateForUndo();
//                           setState(() {
//                             _currentWorldPoints = [
//                               _localToWorld(details.localFocalPoint)
//                             ];
//                           });
//                         } else {
//                           // Scale/pan start
//                           _initialScale = _scale;
//                         }
//                       },
//                       onScaleUpdate: (details) {
//                         // Check if this is drawing (scale is approximately 1.0 and single pointer)
//                         if (details.pointerCount == 1 &&
//                             (details.scale - 1.0).abs() < 0.01) {
//                           // This is a drawing/erasing action
//                           setState(() {
//                             if (_isErasing) {
//                               _handleEraser(
//                                   _localToWorld(details.localFocalPoint));
//                             } else {
//                               _currentWorldPoints
//                                   .add(_localToWorld(details.localFocalPoint));
//                             }
//                           });
//                         } else {
//                           // This is a zoom/pan action
//                           final double computedScale =
//                               _initialScale * details.scale;
//                           if ((computedScale - _scale).abs() > 0.001) {
//                             _showZoomIndicator();
//                           }
//                           final double newScale = computedScale.clamp(0.5, 5.0);
//                           final Offset deltaWorld =
//                               details.focalPointDelta / newScale;
//                           setState(() {
//                             _scale = newScale;
//                             _offset += deltaWorld;
//                           });
//                         }
//                       },
//                       onScaleEnd: (details) {
//                         // Check if we were drawing
//                         if (!_isErasing && _currentWorldPoints.isNotEmpty) {
//                           setState(() {
//                             _strokes.add(
//                               StrokeModel(
//                                 points: List<Offset>.from(_currentWorldPoints),
//                                 color: _currentColor,
//                                 width: _currentStrokeWidth,
//                               ),
//                             );
//                             _currentWorldPoints.clear();
//                           });
//                         }
//                       },
//                       child: Container(
//                         key: _canvasKey,
//                         width: double.infinity,
//                         height: double.infinity,
//                         color: Colors.white,
//                         child: CustomPaint(
//                           painter: HandwritingPainter(
//                             strokes: _strokes,
//                             currentPoints: _currentWorldPoints,
//                             currentColor: _currentColor,
//                             currentWidth: _currentStrokeWidth,
//                             isErasing: _isErasing,
//                             offset: _offset,
//                             scale: _scale,
//                           ),
//                           size: Size.infinite,
//                         ),
//                       ),
//                     ),
//                     // GestureDetector(
//                     //   onPanStart: (details) {
//                     //     if (!_isErasing) {
//                     //       _saveStateForUndo();
//                     //       setState(() {
//                     //         _currentWorldPoints = [_localToWorld(details.localPosition)];
//                     //       });
//                     //     }
//                     //   },
//                     //   onPanUpdate: (details) {
//                     //     setState(() {
//                     //       if (_isErasing) {
//                     //         _handleEraser(_localToWorld(details.localPosition));
//                     //       } else {
//                     //         _currentWorldPoints.add(_localToWorld(details.localPosition));
//                     //       }
//                     //     });
//                     //   },
//                     //   onPanEnd: (_) {
//                     //     if (!_isErasing && _currentWorldPoints.isNotEmpty) {
//                     //       setState(() {
//                     //         _strokes.add(
//                     //           StrokeModel(
//                     //             points: List<Offset>.from(_currentWorldPoints),
//                     //             color: _currentColor,
//                     //             width: _currentStrokeWidth,
//                     //           ),
//                     //         );
//                     //         _currentWorldPoints.clear();
//                     //       });
//                     //     }
//                     //   },
//                     //   onScaleStart: (details) {
//                     //     _initialScale = _scale;
//                     //   },
//                     //   onScaleUpdate: (details) {
//                     //     final double computedScale = _initialScale * details.scale;
//                     //     if ((computedScale - _scale).abs() > 0.001) {
//                     //       _showZoomIndicator();
//                     //     }
//                     //     final double newScale = computedScale.clamp(0.5, 5.0);
//                     //     final Offset deltaWorld = details.focalPointDelta / newScale;
//                     //     setState(() {
//                     //       _scale = newScale;
//                     //       _offset += deltaWorld;
//                     //     });
//                     //   },
//                     //   child: Container(
//                     //     key: _canvasKey,
//                     //     width: double.infinity,
//                     //     height: double.infinity,
//                     //     color: Colors.white,
//                     //     child: CustomPaint(
//                     //       painter: HandwritingPainter(
//                     //         strokes: _strokes,
//                     //         currentPoints: _currentWorldPoints,
//                     //         currentColor: _currentColor,
//                     //         currentWidth: _currentStrokeWidth,
//                     //         isErasing: _isErasing,
//                     //         offset: _offset,
//                     //         scale: _scale,
//                     //       ),
//                     //       size: Size.infinite,
//                     //     ),
//                     //   ),
//                     // ),
//                     Positioned(
//                       top: 20,
//                       right: 16,
//                       child: AnimatedOpacity(
//                         opacity: _showZoom ? 1.0 : 0.0,
//                         duration: const Duration(milliseconds: 200),
//                         child: Material(
//                           color: Colors.transparent,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: Colors.black87,
//                               borderRadius: BorderRadius.circular(20),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.26),
//                                   blurRadius: 4,
//                                   offset: const Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: Text(
//                               '${(_scale * 100).round()}%',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: _strokes.isNotEmpty
//           ? FloatingActionButton.extended(
//               onPressed: () async {
//                 String strokesJson = jsonEncode({
//                   "strokes": _strokes.map((s) => s.toJson()).toList(),
//                 });
//                 // Keep the selected date, only update time for upload
//                 final uploadDateTime = DateTime(
//                   _selectedDateTime.year,
//                   _selectedDateTime.month,
//                   _selectedDateTime.day,
//                   DateTime.now().hour,
//                   DateTime.now().minute,
//                   DateTime.now().second,
//                 );

//                 final imageName = widget.imageModel != null
//                     ? widget.imageModel!.imgName.replaceAll(".json", "")
//                     : DateService.format(
//                         uploadDateTime, "$_dateFormat kk-mm-ss");

//                 await uploadCubit.uploadPhoto(
//                   "",
//                   strokesJson,
//                   "$imageName.json",
//                   "P${widget.patientId}",
//                 );
//               },
//               icon: const Icon(Icons.upload),
//               label: const Text('Upload'),
//             )
//           : FloatingActionButton(
//               onPressed: () {
//                 _showErrorMessage('No notes available to upload');
//               },
//               backgroundColor: Colors.grey,
//               child: const Icon(Icons.upload),
//             ),
//     );
//   }

//   void _handleEraser(Offset worldPosition) {
//     final double eraserRadius = 20.0 / _scale;
//     _strokes.removeWhere((stroke) => stroke.points
//         .any((point) => (point - worldPosition).distance <= eraserRadius));
//   }
// }

// class StrokeModel {
//   final List<Offset> points;
//   final Color color;
//   final double width;

//   StrokeModel({required this.points, required this.color, required this.width});

//   Map<String, dynamic> toJson() {
//     return {
//       "color": "#${color.value.toRadixString(16).padLeft(8, '0')}",
//       "width": width,
//       "points": points.map((p) => {"x": p.dx, "y": p.dy}).toList(),
//     };
//   }

//   static StrokeModel fromJson(Map<String, dynamic> json) {
//     return StrokeModel(
//       color: Color(int.parse(json["color"].substring(1), radix: 16)),
//       width: (json["width"] as num).toDouble(),
//       points: (json["points"] as List)
//           .map((p) => Offset(p["x"].toDouble(), p["y"].toDouble()))
//           .toList(),
//     );
//   }
// }

// class HandwritingPainter extends CustomPainter {
//   final List<StrokeModel> strokes;
//   final List<Offset> currentPoints;
//   final Color currentColor;
//   final double currentWidth;
//   final bool isErasing;
//   final Offset offset;
//   final double scale;

//   HandwritingPainter({
//     required this.strokes,
//     required this.currentPoints,
//     required this.currentColor,
//     required this.currentWidth,
//     this.isErasing = false,
//     required this.offset,
//     required this.scale,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Background
//     final Paint backgroundPaint = Paint()..color = Colors.white;
//     canvas.drawRect(
//         Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

//     final Offset center = Offset(size.width / 2, size.height / 2);

//     canvas.save();
//     canvas.translate(center.dx, center.dy);
//     canvas.translate(offset.dx, offset.dy);
//     canvas.scale(scale, scale);
//     canvas.translate(-center.dx, -center.dy);

//     // Draw grid
//     _drawGrid(canvas, size, scale, offset);

//     // Draw strokes
//     for (final stroke in strokes) {
//       final paint = Paint()
//         ..color = stroke.color
//         ..strokeWidth = stroke.width / scale
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round;

//       if (stroke.points.length > 1) {
//         for (int i = 0; i < stroke.points.length - 1; i++) {
//           canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
//         }
//       }
//     }

//     // Draw current stroke
//     if (!isErasing && currentPoints.isNotEmpty) {
//       final paint = Paint()
//         ..color = currentColor
//         ..strokeWidth = currentWidth / scale
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round;

//       if (currentPoints.length > 1) {
//         for (int i = 0; i < currentPoints.length - 1; i++) {
//           canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
//         }
//       }
//     }

//     canvas.restore();
//   }

//   void _drawGrid(Canvas canvas, Size size, double scale, Offset offset) {
//     final Paint gridPaint = Paint()
//       ..color = Colors.grey.shade300
//       ..strokeWidth = 1.0 / scale
//       ..style = PaintingStyle.stroke;

//     const double spacing = 60.0;

//     final Offset worldTL = _localToWorld(Offset.zero, size, scale, offset);
//     final Offset worldBR =
//         _localToWorld(Offset(size.width, size.height), size, scale, offset);

//     final double minY = math.min(worldTL.dy, worldBR.dy);
//     final double maxY = math.max(worldTL.dy, worldBR.dy);

//     double startY = (minY / spacing).ceilToDouble() * spacing;
//     for (double y = startY; y <= maxY; y += spacing) {
//       canvas.drawLine(
//         const Offset(-1000000.0, 0.0) + Offset(0, y),
//         const Offset(1000000.0, 0.0) + Offset(0, y),
//         gridPaint,
//       );
//     }
//   }

//   Offset _localToWorld(Offset local, Size size, double scale, Offset offset) {
//     final Offset center = Offset(size.width / 2, size.height / 2);
//     Offset temp = local + center;
//     temp = temp / scale;
//     temp = temp - offset;
//     return temp - center;
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }






















//NUMBER 2

// class HandwritingScreen extends StatefulWidget {
//   const HandwritingScreen(
//       {super.key, required this.patientId, this.imageModel});
//   final int patientId;
//   final ImageModel? imageModel;

//   @override
//   _HandwritingScreenState createState() => _HandwritingScreenState();
// }

// class _HandwritingScreenState extends State<HandwritingScreen> {
//   // Drawing state
//   List<StrokeModel> _strokes = [];
//   final List<List<StrokeModel>> _undoStack = [];
//   final List<List<StrokeModel>> _redoStack = [];
//   List<Offset> _currentStrokePoints = [];
//   bool _isErasing = false;

//   // Drawing customization
//   Color _currentColor = Colors.black;
//   double _currentStrokeWidth = 2.5;

//   // Settings and date management
//   String _dateFormat = "dd-MM-yyyy";
//   DateTime _selectedDateTime = DateTime.now();

//   TextEditingController dateController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.imageModel != null &&
//         widget.imageModel!.strokesJson != null &&
//         widget.imageModel!.strokesJson!.isNotEmpty) {
//       // حمّل الـ strokes من JSON
//       _loadStrokesFromJson(widget.imageModel!.strokesJson!);
//     }
//   }

//   void _loadStrokesFromJson(String base64Str) {
//     try {
//       // 1️⃣ أولاً حول Base64 لـ UTF8 string
//       final jsonStr = utf8.decode(base64Decode(base64Str));

//       final Map<String, dynamic> decodedMap = jsonDecode(jsonStr);
//       final List strokesList = decodedMap['strokes'];

//       setState(() {
//         _strokes = strokesList.map((e) => StrokeModel.fromJson(e)).toList();
//       });
//     } catch (e) {
//       debugPrint('Failed to load strokes: $e');
//     }
//   }

//   String get _displayDate {
//     return DateService.format(_selectedDateTime, _dateFormat);
//   }

//   void _saveStateForUndo() {
//     _undoStack.add(List<StrokeModel>.from(_strokes));
//     _redoStack.clear(); // Clear redo stack when new action is performed

//     // Limit undo stack size for memory management
//     if (_undoStack.length > 20) {
//       _undoStack.removeAt(0);
//     }
//   }

//   void _undo() {
//     if (_undoStack.isNotEmpty) {
//       _redoStack.add(List<StrokeModel>.from(_strokes));
//       setState(() {
//         _strokes = _undoStack.removeLast();
//       });
//     }
//   }

//   void _redo() {
//     if (_redoStack.isNotEmpty) {
//       _undoStack.add(List<StrokeModel>.from(_strokes));
//       setState(() {
//         _strokes = _redoStack.removeLast();
//       });
//     }
//   }

//   void _clearCanvas() {
//     if (_strokes.isNotEmpty) {
//       _saveStateForUndo();
//       setState(() {
//         _strokes.clear();
//       });
//     }
//   }

//   Future<void> _selectDate() async {
//     dateController.text = _displayDate;
//     final pickedDate = await showAdaptiveDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text('Select Date'),
//             content: TextFormField(
//               controller: dateController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter date',
//                 hintText: 'dd-MM-yyyy',
//               ),
//               keyboardType: TextInputType.datetime,
//               inputFormatters: [
//                 FilteringTextInputFormatter.digitsOnly,
//                 LengthLimitingTextInputFormatter(8), // ddMMyyyy
//                 FlexibleDateInputFormatter(),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(dateController.text);
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           );
//         });

//     DateTime? parsedDate = DateFormat(_dateFormat).tryParseStrict(pickedDate);
//     if (parsedDate != null) {
//       setState(() {
//         _selectedDateTime = DateTime(
//           parsedDate.year,
//           parsedDate.month,
//           parsedDate.day,
//           _selectedDateTime.hour,
//           _selectedDateTime.minute,
//           _selectedDateTime.second,
//         );
//       });
//     } else if (pickedDate != null && pickedDate.isNotEmpty) {
//       // Show error if date is invalid
//       _showErrorMessage('Invalid date format. Please use dd-MM-yyyy.');
//     }
//   }

//   Future<void> _captureAndUploadImage() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? photo = await picker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 85, // Improved quality
//       );

//       if (photo != null) {
//         final File imageFile = File(photo.path);
//         final Uint8List imageBytes = await imageFile.readAsBytes();
//         final String base64Image = base64Encode(imageBytes);

//         // Keep the selected date for photo upload - only update time
//         final uploadDateTime = DateTime(
//           _selectedDateTime.year,
//           _selectedDateTime.month,
//           _selectedDateTime.day,
//           DateTime.now().hour,
//           DateTime.now().minute,
//           DateTime.now().second,
//         );

//         final imageName =
//             DateService.format(uploadDateTime, "$_dateFormat kk-mm-ss");

//         final uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
//         uploadCubit.uploadPhoto(
//           "",
//           base64Image,
//           "$imageName.png",
//           "P${widget.patientId}",
//         );
//       }
//     } catch (e) {
//       _showErrorMessage('Failed to capture image: ${e.toString()}');
//     }
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   Widget _buildToolbar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Undo button
//           IconButton(
//             onPressed: _undoStack.isEmpty ? null : _undo,
//             icon: const Icon(Icons.undo),
//             tooltip: 'Undo',
//           ),

//           // Redo button
//           IconButton(
//             onPressed: _redoStack.isEmpty ? null : _redo,
//             icon: const Icon(Icons.redo),
//             tooltip: 'Redo',
//           ),

//           const SizedBox(width: 16),

//           // Stroke width slider
//           const Text('Size:'),
//           const SizedBox(width: 8),
//           SizedBox(
//             width: 100,
//             child: Slider(
//               value: _currentStrokeWidth,
//               min: 1.0,
//               max: 10.0,
//               divisions: 9,
//               onChanged: (value) {
//                 setState(() {
//                   _currentStrokeWidth = value;
//                 });
//               },
//             ),
//           ),

//           const Spacer(),

//           // Clear canvas button
//           IconButton(
//             onPressed: _strokes.isEmpty ? null : _clearCanvas,
//             icon: const Icon(Icons.clear_all),
//             tooltip: 'Clear All',
//             color: Colors.red,
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
//     final uploadVisitsCubit =
//         BlocProvider.of<UploadPatientVisitsCubit>(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         title: Text('Patient ${widget.patientId} Notes'),
//         actions: [
//           // Date selector button
//           TextButton.icon(
//             onPressed: _selectDate,
//             icon: const Icon(Icons.calendar_today, size: 16),
//             label: Text(_displayDate),
//             style: TextButton.styleFrom(
//               foregroundColor: Theme.of(context).primaryColor,
//             ),
//           ),

//           // Camera button
//           IconButton(
//             onPressed: _captureAndUploadImage,
//             icon: const Icon(Icons.camera_alt),
//             tooltip: 'Take Photo',
//           ),

//           // Pen/Eraser toggle
//           PenAndEraser(
//             isErasing: _isErasing,
//             onToggle: () {
//               setState(() {
//                 _isErasing = !_isErasing;
//               });
//             },
//           ),
//         ],
//       ),
//       body: BlocConsumer<UploadFilesCubit, UploadFilesState>(
//         listener: (context, state) {
//           if (state is UploadFilesSuccess) {
//             _showSuccessMessage('Upload Successful: ${state.responseString}');

//             Navigator.of(context).pop(true);
//           } else if (state is UploadFilesError) {
//             _showErrorMessage('Upload Error: ${state.errorMessage}');
//           }
//         },
//         builder: (context, state) {
//           if (state is CanvasLoading ||
//               state is UploadingFiles ||
//               state is UploadingPatientVisits) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }

//           return Column(
//             children: [
//               _buildToolbar(),
//               Expanded(
//                 child: GestureDetector(
//                   onPanStart: (details) {
//                     _saveStateForUndo();
//                     if (!_isErasing) {
//                       setState(() {
//                         _currentStrokePoints = [details.localPosition];
//                       });
//                     }
//                   },
//                   onPanUpdate: (details) {
//                     setState(() {
//                       if (_isErasing) {
//                         _handleEraser(details.localPosition);
//                       } else {
//                         _currentStrokePoints.add(details.localPosition);
//                       }
//                     });
//                   },
//                   onPanEnd: (_) {
//                     if (!_isErasing && _currentStrokePoints.isNotEmpty) {
//                       setState(() {
//                         _strokes.add(
//                           StrokeModel(
//                             points: List<Offset>.from(_currentStrokePoints),
//                             color: _currentColor,
//                             width: _currentStrokeWidth,
//                           ),
//                         );
//                         _currentStrokePoints.clear();
//                       });
//                     }
//                   },
//                   child: Container(
//                     width: double.infinity,
//                     height: double.infinity,
//                     color: Colors.white,
//                     child: CustomPaint(
//                       painter: HandwritingPainter(
//                         strokes: _strokes,
//                         currentPoints: _currentStrokePoints,
//                         currentColor: _currentColor,
//                         currentWidth: _currentStrokeWidth,
//                         isErasing: _isErasing,
//                       ),
//                       size: Size.infinite,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: _strokes.isNotEmpty
//           ? FloatingActionButton.extended(
//               onPressed: () async {
//                 String strokesJson = jsonEncode({
//                   "strokes": _strokes.map((s) => s.toJson()).toList(),
//                 });
//                 // Keep the selected date, only update time for upload
//                 final uploadDateTime = DateTime(
//                   _selectedDateTime.year,
//                   _selectedDateTime.month,
//                   _selectedDateTime.day,
//                   DateTime.now().hour,
//                   DateTime.now().minute,
//                   DateTime.now().second,
//                 );

//                 final imageName = widget.imageModel != null
//                     ? widget.imageModel!.imgName.replaceAll(".json", "")
//                     : DateService.format(
//                         uploadDateTime, "$_dateFormat kk-mm-ss");

//                 await uploadCubit.uploadPhoto(
//                   "",
//                   strokesJson,
//                   "$imageName.json",
//                   "P${widget.patientId}",
//                 );
//               },
//               icon: const Icon(Icons.upload),
//               label: const Text('Upload'),
//             )
//           : FloatingActionButton(
//               onPressed: () {
//                 _showErrorMessage('No notes available to upload');
//               },
//               backgroundColor: Colors.grey,
//               child: const Icon(Icons.upload),
//             ),
//     );
//   }

//   void _handleEraser(Offset position) {
//     const double eraserRadius = 20.0;
//     _strokes.removeWhere((stroke) => stroke.points
//         .any((point) => (point - position).distance <= eraserRadius));
//   }
// }

// class StrokeModel {
//   final List<Offset> points;
//   final Color color;
//   final double width;

//   StrokeModel({required this.points, required this.color, required this.width});

//   Map<String, dynamic> toJson() {
//     return {
//       "color": "#${color.value.toRadixString(16).padLeft(8, '0')}",
//       "width": width,
//       "points": points.map((p) => {"x": p.dx, "y": p.dy}).toList(),
//     };
//   }

//   static StrokeModel fromJson(Map<String, dynamic> json) {
//     return StrokeModel(
//       color: Color(int.parse(json["color"].substring(1), radix: 16)),
//       width: (json["width"] as num).toDouble(),
//       points: (json["points"] as List)
//           .map((p) => Offset(p["x"].toDouble(), p["y"].toDouble()))
//           .toList(),
//     );
//   }
// }

// class HandwritingPainter extends CustomPainter {
//   final List<StrokeModel> strokes;
//   final List<Offset> currentPoints;
//   final Color currentColor;
//   final double currentWidth;
//   final bool isErasing;

//   HandwritingPainter({
//     required this.strokes,
//     required this.currentPoints,
//     required this.currentColor,
//     required this.currentWidth,
//     this.isErasing = false,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     // خلفية
//     Paint backgroundPaint = Paint()..color = Colors.white;
//     canvas.drawRect(
//         Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

//     // خطوط أفقية خفيفة (اختياري)
//     _drawGrid(canvas, size);

//     // ✏️ ارسم الـ strokes (المخزنة والمحملة من JSON)
//     for (final stroke in strokes) {
//       final paint = Paint()
//         ..color = stroke.color
//         ..strokeWidth = stroke.width
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round;

//       if (stroke.points.length > 1) {
//         for (int i = 0; i < stroke.points.length - 1; i++) {
//           canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
//         }
//       }
//     }

//     // ✏️ ارسم الخط الحالي (Current Stroke)
//     if (!isErasing && currentPoints.isNotEmpty) {
//       final paint = Paint()
//         ..color = currentColor
//         ..strokeWidth = currentWidth
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round;

//       if (currentPoints.length > 1) {
//         for (int i = 0; i < currentPoints.length - 1; i++) {
//           canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
//         }
//       }
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

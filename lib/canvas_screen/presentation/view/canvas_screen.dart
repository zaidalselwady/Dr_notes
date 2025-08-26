// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_write_notes/core/date_format_service.dart';
import 'package:hand_write_notes/core/repos/data_repo_impl.dart';
import 'package:hand_write_notes/core/utils/api_service.dart';
import 'package:hand_write_notes/get_proc_cubit/cubit/get_proc_cubit.dart';
import 'package:hand_write_notes/patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
import 'package:hand_write_notes/settings.dart';
import 'package:hand_write_notes/upload_files_cubit/cubit/upload_files_cubit.dart';
import 'package:image_picker/image_picker.dart';
import '../../../convert_canvas_B64_cubit/cubit/convert_canvas_b64_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/hand_writing_painter.dart';
import 'widgets/pen_eraser.dart';
import 'widgets/proc_dialog.dart';

class HandwritingScreen extends StatefulWidget {
  const HandwritingScreen({super.key, required this.patientId});
  final int patientId;

  @override
  _HandwritingScreenState createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends State<HandwritingScreen> {
  // Drawing state
  final List<MapEntry<Path, Paint>> _paths = [];
  final List<List<MapEntry<Path, Paint>>> _undoStack = [];
  final List<List<MapEntry<Path, Paint>>> _redoStack = [];
  Path _currentPath = Path();
  bool _isErasing = false;

  // Drawing customization
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.5;

  // Settings and date management
  final SettingsService _settingsScreen = SettingsService();
  String _dateFormat = "dd-MM-yyyy";
  DateTime _selectedDateTime = DateTime.now();

  // Constants for performance optimization
  static const int _maxPaths = 1000;
  static const int _pathCleanupBatch = 100;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _dateFormat = _settingsScreen.getString(
      AppSettingsKeys.dateFormat,
      defaultValue: "dd-MM-yyyy",
    );
  }

  String get _formattedImageName {
    return DateService.format(_selectedDateTime, "$_dateFormat kk-mm-ss");
  }

  String get _displayDate {
    return DateService.format(_selectedDateTime, _dateFormat);
  }

  void _saveStateForUndo() {
    _undoStack.add(List<MapEntry<Path, Paint>>.from(_paths));
    _redoStack.clear(); // Clear redo stack when new action is performed

    // Limit undo stack size for memory management
    if (_undoStack.length > 20) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(List<MapEntry<Path, Paint>>.from(_paths));
      setState(() {
        _paths.clear();
        if (_undoStack.isNotEmpty) {
          _paths.addAll(_undoStack.removeLast());
        }
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(List<MapEntry<Path, Paint>>.from(_paths));
      setState(() {
        _paths.clear();
        _paths.addAll(_redoStack.removeLast());
      });
    }
  }

  void _clearCanvas() {
    if (_paths.isNotEmpty) {
      _saveStateForUndo();
      setState(() {
        _paths.clear();
      });
    }
  }

  void _optimizePathsIfNeeded() {
    if (_paths.length > _maxPaths) {
      final pathsToRemove = _paths.length - _maxPaths + _pathCleanupBatch;
      _paths.removeRange(0, pathsToRemove);
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDateTime,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        locale: const Locale('en', 'GB'),
        initialEntryMode: DatePickerEntryMode.input);

    if (pickedDate != null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
          _selectedDateTime.second,
        );
      });
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
          imageName,
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
            onPressed: _paths.isEmpty ? null : _clearCanvas,
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
    final convertCubit = BlocProvider.of<ConvertCanvasB64Cubit>(context);
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
      body: MultiBlocListener(
        listeners: [
          BlocListener<ConvertCanvasB64Cubit, ConvertCanvasB64State>(
            listener: (context, state) async {
              if (state is CanvasConversionSuccess) {
                // Keep the selected date, only update time for upload
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

                await uploadCubit.uploadPhoto(
                  "",
                  state.base64Image,
                  imageName,
                  "P${widget.patientId}",
                );

                uploadVisitsCubit.uploadPatientVisits(
                  widget.patientId,
                  state.procedures,
                  imageName,
                  "",
                );
              } else if (state is CanvasConversionError) {
                _showErrorMessage('Conversion Error: ${state.errorMessage}');
              }
            },
          ),
        ],
        child: BlocConsumer<UploadFilesCubit, UploadFilesState>(
          listener: (context, state) {
            if (state is UploadFilesSuccess) {
              _showSuccessMessage('Upload Successful: ${state.responseString}');
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.of(context).pop(true);
              });
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
                  child: GestureDetector(
                    onPanStart: (details) {
                      if (!_isErasing) {
                        _saveStateForUndo();
                        setState(() {
                          _currentPath = Path();
                          _currentPath.moveTo(
                            details.localPosition.dx,
                            details.localPosition.dy,
                          );
                        });
                      }
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        if (_isErasing) {
                          _handleEraser(details.localPosition);
                        } else {
                          _currentPath.lineTo(
                            details.localPosition.dx,
                            details.localPosition.dy,
                          );
                        }
                      });
                    },
                    onPanEnd: (_) {
                      if (!_isErasing && _currentPath != Path()) {
                        setState(() {
                          _paths.add(
                            MapEntry(
                              _currentPath,
                              _createPaint(_currentColor, _currentStrokeWidth),
                            ),
                          );
                          _currentPath = Path();
                          _optimizePathsIfNeeded();
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white,
                      child: CustomPaint(
                        painter: HandwritingPainter(
                          _paths,
                          _currentPath,
                          _isErasing,
                          Paint()
                            ..color = _currentColor
                            ..strokeCap = StrokeCap.round
                            ..strokeWidth = _currentStrokeWidth
                            ..style = PaintingStyle.stroke,
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
      ),
      floatingActionButton: _paths.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                try {
                  final selectedProcedures = await showDialog<List<dynamic>>(
                    context: context,
                    builder: (BuildContext context) {
                      return BlocProvider(
                        create: (context) => GetProcCubit(
                          DataRepoImpl(ApiService(Dio())),
                        )..fetchPatientsWithSoapRequest(
                            "SELECT mp.Main_Procedure_id,mp.Main_Procedure_Desc,pp.Procedure_Desc,pp.Procedure_id "
                            "FROM Patients_Main_Procedures mp "
                            "INNER JOIN Patients_Procedures pp ON mp.Main_Procedure_id = pp.Main_Procedure_id"),
                        child: const ProcedureSelectionScreen(),
                      );
                    },
                  );

                  if (context.mounted && selectedProcedures != null) {
                    // Don't update the selected date - keep user's choice
                    convertCubit.convertCanvasToB64(
                      context,
                      _paths,
                      _currentPath,
                      _isErasing,
                      selectedProcedures,
                    );
                  }
                } catch (e) {
                  _showErrorMessage('Failed to process notes: ${e.toString()}');
                }
              },
              icon: const Icon(Icons.upload),
              label: const Text('Upload Notes'),
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

  Paint _createPaint(Color color, double strokeWidth) {
    return Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
  }

  void _handleEraser(Offset position) {
    const double eraserRadius = 20.0;
    _paths.removeWhere((entry) {
      return _isPathNearPosition(entry.key, position, eraserRadius);
    });
  }

  bool _isPathNearPosition(Path path, Offset position, double radius) {
    // Simple approximation - check if path contains point within radius
    final bounds = path.getBounds();
    return bounds.contains(position) ||
        (bounds.center - position).distance < radius;
  }
}

// Keep your existing RecognizedText widget
class RecognizedText extends StatelessWidget {
  const RecognizedText({super.key, required this.base64Image});
  final String base64Image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recognized Text')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              base64Image,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
























// // ignore_for_file: library_private_types_in_public_api

// import 'dart:convert';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hand_write_notes/core/date_format_service.dart';
// import 'package:hand_write_notes/core/repos/data_repo_impl.dart';
// import 'package:hand_write_notes/core/utils/api_service.dart';
// import 'package:hand_write_notes/get_proc_cubit/cubit/get_proc_cubit.dart';
// import 'package:hand_write_notes/patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
// import 'package:hand_write_notes/settings.dart';
// import 'package:hand_write_notes/upload_files_cubit/cubit/upload_files_cubit.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../../convert_canvas_B64_cubit/cubit/convert_canvas_b64_cubit.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'widgets/hand_writing_painter.dart';
// import 'widgets/pen_eraser.dart';
// import 'widgets/proc_dialog.dart';

// class HandwritingScreen extends StatefulWidget {
//   const HandwritingScreen({super.key, required this.patientId});
//   final int patientId;

//   @override
//   _HandwritingScreenState createState() => _HandwritingScreenState();
// }

// class _HandwritingScreenState extends State<HandwritingScreen> {
//   final List<MapEntry<Path, Paint>> _paths =
//       []; // Store paths with paint for each stroke
//   Path _currentPath = Path();
//   bool _isErasing = false;
//   SettingsService _settingsScreen = SettingsService();
//   String dateFormat = "dd-MM-yyyy"; // Default format
//   DateTime now = DateTime.now();
//   String formattedDate = "";
//   String imageName = ""; // Format date for file naming
//   String textBtnDate = "";
//   @override
//   initState() {
//     super.initState();
//     // Load settings if needed
//     dateFormat = _settingsScreen.getString(AppSettingsKeys.dateFormat,
//         defaultValue: "dd-MM-yyyy");
//     formattedDate = DateService.format(
//         now, "$dateFormat kk-mm-ss"); // Format date for file naming
//     imageName = formattedDate;
//     textBtnDate = formattedDate.split(" ")[0];
//     print("Date format: $formattedDate");
//   }

//   @override
//   Widget build(BuildContext context) {
//     // DateTime now = DateTime.now();
//     // String formattedDate = DateService.format(
//     //     now, "$dateFormat kk-mm-ss"); // Format date for file naming
//     // String textBtnDate = formattedDate.split(" ")[0];
//     final ImagePicker picker = ImagePicker();
//     var convertCubit = BlocProvider.of<ConvertCanvasB64Cubit>(context);
//     var uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
//     var uploadVisitsCubit = BlocProvider.of<UploadPatientVisitsCubit>(context);
//     String currentImageName = "";

//     Future<void> captureAndUploadImage() async {
//       try {
//         // Open the camera and capture the image
//         final XFile? photo = await picker.pickImage(
//             source: ImageSource.camera, imageQuality: 10);
//         if (photo != null) {
//           // Read the image file
//           File imageFile = File(photo.path);
//           // Convert the image to Base64
//           Uint8List imageBytes = await imageFile.readAsBytes();
//           String base64Image = base64Encode(imageBytes);
//           uploadCubit.uploadPhoto(
//               "", base64Image, imageName, "P${widget.patientId}");
//         }
//       } catch (e) {}
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         actions: [
//           StatefulBuilder(
//             builder: (context, setState) => TextButton(
//               onPressed: () {
//                 showDatePicker(
//                   context: context,
//                   initialDate: DateTime.now(),
//                   firstDate: DateTime(2000),
//                   lastDate: DateTime.now(),
//                   initialEntryMode: DatePickerEntryMode.input,
//                 ).then((pickedDate) {
//                   if (pickedDate != null) {
//                     final newDateTime = DateTime(
//                       pickedDate.year,
//                       pickedDate.month,
//                       pickedDate.day,
//                       now.hour,
//                       now.minute,
//                       now.second,
//                     );
//                     final selectedDateTime = DateService.format(
//                       newDateTime,
//                       dateFormat,
//                     );
//                     setState(() {
//                       textBtnDate = selectedDateTime;
//                       formattedDate = DateService.format(
//                         selectedDateTime,
//                         "$dateFormat kk-mm-ss",
//                       );
//                       imageName = formattedDate;
//                     });
//                   }
//                 });
//               },
//               child: Text(
//                 textBtnDate,
//               ),
//             ),
//           ),
//           IconButton(
//             onPressed: () {
//               captureAndUploadImage();
//             },
//             icon: const Icon(
//               Icons.camera_alt,
//             ),
//           ),
//           PenAndEraser(
//             isErasing: _isErasing,
//             onToggle: () {
//               setState(() {
//                 _isErasing = !_isErasing; // Toggle eraser mode
//               });
//             },
//           ),
//         ],
//       ),
//       body: MultiBlocListener(
//         listeners: [
//           BlocListener<ConvertCanvasB64Cubit, ConvertCanvasB64State>(
//             listener: (context, state) async {
//               if (state is CanvasConversionSuccess) {
//                 currentImageName = state.base64Image;

//                 formattedDate = DateService.format(
//                   formattedDate,
//                   "$dateFormat kk-mm-ss",
//                 );
//                 imageName = formattedDate;
//                 await uploadCubit.uploadPhoto(
//                     "", state.base64Image, imageName, "P${widget.patientId}");
//                 if (state.procedures.isNotEmpty) {
//                   uploadVisitsCubit.uploadPatientVisits(
//                       widget.patientId, state.procedures, imageName, "");
//                 }
//               } else if (state is CanvasConversionError) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Conversion Error: ${state.errorMessage}'),
//                   ),
//                 );
//               }
//             },
//           ),
//         ],
//         child: BlocConsumer<UploadFilesCubit, UploadFilesState>(
//             listener: (context, state) {
//           if (state is UploadFilesSuccess) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Upload Successful: ${state.responseString}'),
//               ),
//             );
//             Future.delayed(const Duration(seconds: 1), () {
//               Navigator.of(context).pop(true);
//             });
//           } else if (state is UploadFilesError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Upload Error: ${state.errorMessage}'),
//               ),
//             );
//           }
//         }, builder: (context, state) {
//           if (state is CanvasLoading ||
//               state is UploadingFiles ||
//               state is UploadingPatientVisits) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//           return GestureDetector(
//             onPanStart: (details) {
//               setState(() {
//                 if (!_isErasing) {
//                   _currentPath = Path(); // Start new path for drawing
//                   _currentPath.moveTo(
//                       details.localPosition.dx, details.localPosition.dy);
//                 }
//               });
//             },
//             onPanUpdate: (details) {
//               setState(() {
//                 if (_isErasing) {
//                   _handleEraser(details.localPosition);
//                 } else {
//                   _currentPath.lineTo(
//                       details.localPosition.dx, details.localPosition.dy);
//                 }
//               });
//             },
//             onPanEnd: (_) {
//               setState(() {
//                 if (!_isErasing) {
//                   _paths.add(
//                     MapEntry(
//                       _currentPath,
//                       _createPaint(Colors.black, 2.5),
//                     ),
//                   );
//                 }
//                 _currentPath = Path();
//               });
//             },
//             child: CustomPaint(
//               painter: HandwritingPainter(_paths, _currentPath, _isErasing),
//               size: Size.infinite,
//             ),
//           );
//         }),
//       ),
//       floatingActionButton: BlocProvider(
//         create: (context) => GetProcCubit(
//           DataRepoImpl(
//             ApiService(
//               Dio(),
//             ),
//           ),
//         ),
//         child: FloatingActionButton(
//           onPressed: () async {
//             if (_paths.isNotEmpty) {
//               List<dynamic>? selectedProcedures =
//                   await showDialog<List<dynamic>>(
//                 context: context,
//                 builder: (BuildContext context) {
//                   return BlocProvider(
//                     create: (context) => GetProcCubit(
//                       DataRepoImpl(
//                         ApiService(
//                           Dio(),
//                         ),
//                       ),
//                     )..fetchPatientsWithSoapRequest(
//                         "SELECT mp.Main_Procedure_id,mp.Main_Procedure_Desc,pp.Procedure_Desc,pp.Procedure_id FROM Patients_Main_Procedures mp INNER JOIN Patients_Procedures pp ON mp.Main_Procedure_id = pp.Main_Procedure_id"),
//                     child: const ProcedureSelectionScreen(),
//                   ); // Your dialog
//                 },
//               );
//               if (context.mounted && selectedProcedures != null) {
//                 convertCubit.convertCanvasToB64(context, _paths, _currentPath,
//                     _isErasing, selectedProcedures);
//               }
//             } else {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('No notes available'),
//                 ),
//               );
//             }
//           },
//           child: const Icon(Icons.upload),
//         ),
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
//     _paths.removeWhere((entry) => entry.key.contains(position));
//   }
// }

// class RecognizedText extends StatelessWidget {
//   const RecognizedText({super.key, required this.base64Image});
//   final String base64Image;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Center(
//             child: Text(
//               base64Image,
//               style: const TextStyle(fontSize: 20, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // BlocListener<RecognizetextCubit, RecognizetextState>(
// //               listener: (context, state) {
// //                 if (state is RecognizetextSuccess) {
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                         builder: (context) =>
// //                             RecognizedText(base64Image: state.text)),
// //                   );
// //                 } else if (state is RecognizetextFailed) {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(
// //                       content: Text('Conversion Error: ${state.message}'),
// //                     ),
// //                   );
// //                 }
// //               },
// //             ),



// // List<int>? selectedProcedures = await showDialog<List<int>>(
//             //   context: context,
//             //   builder: (BuildContext context) {
//             //     return BlocProvider(
//             //       create: (context) => GetProcCubit(
//             //         DataRepoImpl(
//             //           ApiService(
//             //             Dio(),
//             //           ),
//             //         ),
//             //       )..fetchPatientsWithSoapRequest(
//             //           "Select * FROM Patients_Procedures"),
//             //       child: const ProcedureSelectionDialog(),
//             //     ); // Your dialog
//             //   },
//             // );

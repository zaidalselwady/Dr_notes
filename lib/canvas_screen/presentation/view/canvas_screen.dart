// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_write_notes/core/repos/data_repo_impl.dart';
import 'package:hand_write_notes/core/utils/api_service.dart';
import 'package:hand_write_notes/get_proc_cubit/cubit/get_proc_cubit.dart';
import 'package:hand_write_notes/patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
import 'package:hand_write_notes/upload_files_cubit/cubit/upload_files_cubit.dart';
import 'package:image_picker/image_picker.dart';
import '../../../convert_canvas_B64_cubit/cubit/convert_canvas_b64_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../main.dart';
import 'widgets/hand_writing_painter.dart';
import 'widgets/pen_eraser.dart';
import 'package:intl/intl.dart';

import 'widgets/proc_dialog.dart';

class HandwritingScreen extends StatefulWidget {
  const HandwritingScreen({super.key, required this.patientId});
  final int patientId;

  @override
  _HandwritingScreenState createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends State<HandwritingScreen> {
  final List<MapEntry<Path, Paint>> _paths =
      []; // Store paths with paint for each stroke
  Path _currentPath = Path();
  bool _isErasing = false;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd kk-mm').format(now);
    String textBtnDate = formattedDate.split(" ")[0];
    final ImagePicker picker = ImagePicker();
    var convertCubit = BlocProvider.of<ConvertCanvasB64Cubit>(context);
    var uploadCubit = BlocProvider.of<UploadFilesCubit>(context);
    var uploadVisitsCubit = BlocProvider.of<UploadPatientVisitsCubit>(context);
    String currentImageName = "";

    Future<void> captureAndUploadImage() async {
      try {
        // Open the camera and capture the image
        final XFile? photo = await picker.pickImage(
            source: ImageSource.camera, imageQuality: 10);
        if (photo != null) {
          // Read the image file
          File imageFile = File(photo.path);
          // Convert the image to Base64
          Uint8List imageBytes = await imageFile.readAsBytes();
          String base64Image = base64Encode(imageBytes);
          uploadCubit.uploadPhoto(
              "folderName", base64Image, formattedDate, "P${widget.patientId}");
        }
      } catch (e) {}
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          StatefulBuilder(
            builder: (context, setState) => TextButton(
              onPressed: () {
                showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                ).then((pickedDate) {
                  if (pickedDate != null) {
                    final now = DateTime.now();
                    final selectedDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      now.hour,
                      now.minute,
                    );
                    setState(() {
                      textBtnDate =
                          "${selectedDateTime.toLocal()}".split(' ')[0];
                      formattedDate = DateFormat('yyyy-MM-dd HH-mm')
                          .format(selectedDateTime);
                    });
                  }
                });
              },
              child: Text(
                textBtnDate,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              captureAndUploadImage();
            },
            icon: const Icon(
              Icons.camera_alt,
            ),
          ),
          PenAndEraser(
            isErasing: _isErasing,
            onToggle: () {
              setState(() {
                _isErasing = !_isErasing; // Toggle eraser mode
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
                currentImageName = state.base64Image;
                now = DateTime.now();
                formattedDate = DateFormat('yyyy-MM-dd kk-mm-ss').format(now);
                await uploadCubit.uploadPhoto("", state.base64Image,
                    formattedDate, "P${widget.patientId}");
                if (state.procedures.isNotEmpty) {
                  uploadVisitsCubit.uploadPatientVisits(
                      widget.patientId, state.procedures, formattedDate, "");
                }
              } else if (state is CanvasConversionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Conversion Error: ${state.errorMessage}'),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocConsumer<UploadFilesCubit, UploadFilesState>(
            listener: (context, state) {
          if (state is UploadFilesSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload Successful: ${state.responseString}'),
              ),
            );
            Navigator.of(context).pop(currentImageName);
          } else if (state is UploadFilesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload Error: ${state.errorMessage}'),
              ),
            );
          }
        }, builder: (context, state) {
          if (state is CanvasLoading ||
              state is UploadingFiles ||
              state is UploadingPatientVisits) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return GestureDetector(
            onPanStart: (details) {
              setState(() {
                if (!_isErasing) {
                  _currentPath = Path(); // Start new path for drawing
                  _currentPath.moveTo(
                      details.localPosition.dx, details.localPosition.dy);
                }
              });
            },
            onPanUpdate: (details) {
              setState(() {
                if (_isErasing) {
                  _handleEraser(details.localPosition);
                } else {
                  _currentPath.lineTo(
                      details.localPosition.dx, details.localPosition.dy);
                }
              });
            },
            onPanEnd: (_) {
              setState(() {
                if (!_isErasing) {
                  _paths.add(
                    MapEntry(
                      _currentPath,
                      _createPaint(Colors.black, 2.5),
                    ),
                  );
                }
                _currentPath = Path();
              });
            },
            child: CustomPaint(
              painter: HandwritingPainter(_paths, _currentPath, _isErasing),
              size: Size.infinite,
            ),
          );
        }),
      ),
      floatingActionButton: BlocProvider(
        create: (context) => GetProcCubit(
          DataRepoImpl(
            ApiService(
              Dio(),
            ),
          ),
        ),
        child: FloatingActionButton(
          onPressed: () async {
            if (_paths.isNotEmpty) {
              List<dynamic>? selectedProcedures =
                  await showDialog<List<dynamic>>(
                context: context,
                builder: (BuildContext context) {
                  return BlocProvider(
                    create: (context) => GetProcCubit(
                      DataRepoImpl(
                        ApiService(
                          Dio(),
                        ),
                      ),
                    )..fetchPatientsWithSoapRequest(
                        "SELECT mp.Main_Procedure_id,mp.Main_Procedure_Desc,pp.Procedure_Desc,pp.Procedure_id FROM Patients_Main_Procedures mp INNER JOIN Patients_Procedures pp ON mp.Main_Procedure_id = pp.Main_Procedure_id"),
                    child:   const ProcedureSelectionScreen(),
                  ); // Your dialog
                },
              );
              if (context.mounted) {
                convertCubit.convertCanvasToB64(context, _paths, _currentPath,
                    _isErasing, selectedProcedures!);
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No notes available'),
                ),
              );
            }
          },
          child: const Icon(Icons.upload),
        ),
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
    // Remove paths intersecting with the eraser
    _paths.removeWhere((entry) => entry.key.contains(position));
  }
}

class RecognizedText extends StatelessWidget {
  const RecognizedText({super.key, required this.base64Image});
  final String base64Image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              base64Image,
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// BlocListener<RecognizetextCubit, RecognizetextState>(
//               listener: (context, state) {
//                 if (state is RecognizetextSuccess) {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) =>
//                             RecognizedText(base64Image: state.text)),
//                   );
//                 } else if (state is RecognizetextFailed) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Conversion Error: ${state.message}'),
//                     ),
//                   );
//                 }
//               },
//             ),



// List<int>? selectedProcedures = await showDialog<List<int>>(
            //   context: context,
            //   builder: (BuildContext context) {
            //     return BlocProvider(
            //       create: (context) => GetProcCubit(
            //         DataRepoImpl(
            //           ApiService(
            //             Dio(),
            //           ),
            //         ),
            //       )..fetchPatientsWithSoapRequest(
            //           "Select * FROM Patients_Procedures"),
            //       child: const ProcedureSelectionDialog(),
            //     ); // Your dialog
            //   },
            // );

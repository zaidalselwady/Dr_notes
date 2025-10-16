import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import 'package:hand_write_notes/patient_visits_screen/presentation/manger/patient_questionnaire_cubit/cubit/patient_questionnaire_cubit.dart';
import 'package:hand_write_notes/patient_visits_screen/presentation/view/visit_images.dart';
import 'package:hand_write_notes/questionnaire_screen/presentation/view/questionnaire.dart';
import 'package:hand_write_notes/show_info_screen/presentation/view/show_info_screen.dart';
import 'package:intl/intl.dart';
import '../../../core/repos/data_repo_impl.dart';
import '../../../core/utils/api_service.dart';
import '../../../login_screen/data/user_model.dart';
import '../../../show_info_screen/presentation/manger/update_patient_info_cubit/cubit/update_patient_info_cubit.dart';
import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import '../../data/image_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientVisitsScreen extends StatefulWidget {
  const PatientVisitsScreen(
      {super.key,
      required this.patientId,
      required this.patientsInfo,
      required this.user});
  final int patientId;
  final PatientInfo patientsInfo;
  final User user;

  @override
  State<PatientVisitsScreen> createState() => _PatientVisitsScreenState();
}

class _PatientVisitsScreenState extends State<PatientVisitsScreen> {
  List<ImageModel> images = [];
  int calculateAgeInYears(String birthDate) {
    try {
      // Define possible date formats
      final List<String> dateFormats = [
        'd-M-yyyy',
        'dd-MM-yyyy',
        'yyyy-MM-dd',
        'dd/MM/yyyy'
      ];

      DateTime? parsedDate;
      for (String format in dateFormats) {
        try {
          parsedDate = DateFormat(format).parseStrict(birthDate);
          break; // Exit loop if parsing succeeds
        } catch (_) {
          continue; // Try the next format
        }
      }

      // Throw an error if no format matched
      if (parsedDate == null) {
        throw FormatException(
            "Invalid date format. Expected formats: ${dateFormats.join(', ')}");
      }

      // Get the current date
      final DateTime today = DateTime.now();
      // Calculate the difference in years
      int age = today.year - parsedDate.year;
      // Adjust for cases where the birth date has not occurred yet this year
      if (today.month < parsedDate.month ||
          (today.month == parsedDate.month && today.day < parsedDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      throw FormatException("Invalid date format: $birthDate");
    }
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int age = calculateAgeInYears(widget.patientsInfo.birthDate);

    return Scaffold(
      appBar: AppBar(),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Always visible patient info card
              PatientInfoCard(
                user: widget.user,
                patientInfo: widget.patientsInfo,
                medicalHistory: "",
                age: age.toString(),
              ),
              if (widget.user.userName == "Dr")
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StickyNote(
                      patientId: widget.patientsInfo.patientId.toString(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientInfoCard extends StatelessWidget {
  final String age;
  final User user;
  final String medicalHistory;
  final PatientInfo patientInfo;
  const PatientInfoCard({
    super.key,
    required this.age,
    required this.medicalHistory,
    required this.patientInfo,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/patients.png"),
            opacity: 0.2,
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row for profile picture and basic info
              Row(
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BlocProvider(
                                  create: (context) => UpdatePatientInfoCubit(
                                    DataRepoImpl(
                                      ApiService(
                                        Dio(),
                                      ),
                                    ),
                                  ),
                                  child:
                                      ShowInfoScreen(patientInfo: patientInfo),
                                )),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.teal[800], // Background color
                      radius: 40, // Adjust CircleAvatar size
                      child: ClipOval(
                        child: Image.asset(
                          "assets/tooth.png",
                          fit: BoxFit.contain, // Ensures the image fits well
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Basic Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocListener<UpdatePatientStateCubit,
                          UpdatePatientStateState>(
                        listener: (context, state) {
                          if (state is UpdatePatientStateSuccess) {
                            Navigator.pop(context);
                          } else if (state is UpdatingPatientState) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Updating patient...'),
                              ),
                            );
                          }
                        },
                        child: Text(
                          patientInfo.name,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Age: $age",
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Contact: ${patientInfo.phone}",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 1),
              // Medical History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BlocConsumer<PatientQuestionnaireCubit,
                      PatientQuestionnaireState>(
                    listener: (context, state) {
                      if (state is GetPatientQuestionnaireSuccess) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DecoratedQuestionnaireScreen(
                              answers: state.patientQuestionnaireModel,
                              isNavigateFromVisitScreen: true,
                              childInfo: patientInfo,
                            ),
                          ),
                        );
                      } else if (state is GetPatientQuestionnaireFailed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.error,
                            ),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is GettingPatientQuestionnaire) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return TextButton(
                        onPressed: () {
                          context
                              .read<PatientQuestionnaireCubit>()
                              .fetchPatientsWithSoapRequest(
                                  patientInfo.patientId);
                        },
                        child: const Text(
                          "Medical History",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior
                        .opaque, // 👈 هذا كمان مهم لتوسيع منطقة اللمس
                    onTap: () {
                      if (user.userName == "Dr") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VisitImages(patientInfo: patientInfo),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No access to this feature"),
                          ),
                        );
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          //Icon(Icons.image, color: Colors.teal[300], size: 30),
                          Positioned(
                            right: 5,
                            top: 5,
                            child: Icon(Icons.image,
                                color: Colors.teal[300], size: 30),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Icon(Icons.image,
                                color: Colors.teal[600], size: 30),
                          ),
                          Positioned(
                            right: 15,
                            top: 15,
                            child: Icon(Icons.image,
                                color: Colors.teal[900], size: 30),
                          ),
                        ],
                      ),
                    ),
                  )

                  // GestureDetector(
                  //   onTap: () {
                  //     if (user.userName == "Dr") {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => VisitImages(
                  //             patientInfo: patientInfo,
                  //           ),
                  //         ),
                  //       );
                  //     } else {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(
                  //           content: Text(
                  //             "No access to this feature",
                  //           ),
                  //         ),
                  //       );
                  //     }
                  //   },
                  //   child: SizedBox(
                  //     height: 50,
                  //     child: Stack(
                  //       clipBehavior: Clip.none,
                  //       children: [
                  //         Icon(
                  //           Icons.image,
                  //           color: Colors.teal[300],
                  //         ),
                  //         Positioned(
                  //             right: 5,
                  //             top: 5,
                  //             child: Icon(
                  //               Icons.image,
                  //               color: Colors.teal[600],
                  //             )),
                  //         Positioned(
                  //             right: 10,
                  //             top: 10,
                  //             child: Icon(
                  //               Icons.image,
                  //               color: Colors.teal[900],
                  //             )),
                  //       ],
                  //     ),
                  //   ),
                  // )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Stroke {
  List<Offset> points;
  double strokeWidth;
  Color color;
  bool isErased;

  Stroke({
    required this.points,
    this.strokeWidth = 3.0,
    this.color = Colors.black,
    this.isErased = false,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((e) => {'x': e.dx, 'y': e.dy}).toList(),
        'strokeWidth': strokeWidth,
        'color': color.value,
        'isErased': isErased,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points:
          (json['points'] as List).map((p) => Offset(p['x'], p['y'])).toList(),
      strokeWidth: json['strokeWidth']?.toDouble() ?? 3.0,
      color: Color(json['color'] ?? Colors.black.value),
      isErased: json['isErased'] ?? false,
    );
  }

  // Create a path from points for smoother drawing
  Path get path {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);

    if (points.length == 1) {
      // Single point - draw a small circle
      path.addOval(
          Rect.fromCircle(center: points.first, radius: strokeWidth / 2));
    } else if (points.length == 2) {
      // Two points - draw a line
      path.lineTo(points.last.dx, points.last.dy);
    } else {
      // Multiple points - create smooth curve
      for (int i = 1; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlPoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );
        path.quadraticBezierTo(
            current.dx, current.dy, controlPoint.dx, controlPoint.dy);
      }
      path.lineTo(points.last.dx, points.last.dy);
    }

    return path;
  }

  // Check if this stroke intersects with an eraser area
  bool intersectsWithEraser(Offset eraserCenter, double eraserRadius) {
    return points
        .any((point) => (point - eraserCenter).distance <= eraserRadius);
  }
}

enum DrawingMode { pen, eraser }

class StickyNote extends StatefulWidget {
  final String patientId;
  const StickyNote({required this.patientId, super.key});

  @override
  State<StickyNote> createState() => _StickyNoteState();
}

class _StickyNoteState extends State<StickyNote> {
  List<Stroke> strokes = [];
  List<List<Stroke>> history = [];
  DrawingMode currentMode = DrawingMode.pen;
  Color selectedColor = Colors.black;
  double selectedStrokeWidth = 3.0;
  double eraserSize = 20.0;

  Offset? currentEraserPosition;
  bool isDrawing = false;

  final GlobalKey _drawingAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadStrokes();
  }

  Future<void> _loadStrokes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('sticky_note_${widget.patientId}');
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      setState(() {
        strokes = decoded.map((e) => Stroke.fromJson(e)).toList();
        _saveToHistory();
      });
    }
  }

  Future<void> _saveStrokes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(strokes.map((e) => e.toJson()).toList());
    await prefs.setString('sticky_note_${widget.patientId}', jsonString);
  }

  void _saveToHistory() {
    history.add(List<Stroke>.from(strokes));
    if (history.length > 20) {
      // Limit history size
      history.removeAt(0);
    }
  }

  void _undo() {
    if (history.length > 1) {
      setState(() {
        history.removeLast(); // Remove current state
        strokes = List<Stroke>.from(history.last); // Restore previous state
      });
      _saveStrokes();
    }
  }

  void _clearAll() {
    _saveToHistory();
    setState(() {
      strokes.clear();
    });
    _saveStrokes();
  }

  Offset? _getLocalPosition(Offset globalPosition) {
    final RenderBox? renderBox =
        _drawingAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.globalToLocal(globalPosition);
    }
    return null;
  }

  void _handlePanStart(DragStartDetails details) {
    final localPosition = _getLocalPosition(details.globalPosition);
    if (localPosition == null) return;

    setState(() {
      isDrawing = true;
      if (currentMode == DrawingMode.pen) {
        _saveToHistory();
        strokes.add(Stroke(
          points: [localPosition],
          strokeWidth: selectedStrokeWidth,
          color: selectedColor,
        ));
      } else {
        currentEraserPosition = localPosition;
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final localPosition = _getLocalPosition(details.globalPosition);
    if (localPosition == null) return;

    setState(() {
      if (currentMode == DrawingMode.pen) {
        if (strokes.isNotEmpty) {
          strokes.last.points.add(localPosition);
        }
      } else {
        currentEraserPosition = localPosition;
        // Erase strokes that intersect with eraser
        for (var stroke in strokes) {
          if (!stroke.isErased &&
              stroke.intersectsWithEraser(localPosition, eraserSize)) {
            stroke.isErased = true;
          }
        }
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      isDrawing = false;
      currentEraserPosition = null;
      if (currentMode == DrawingMode.eraser) {
        // Remove erased strokes
        strokes.removeWhere((stroke) => stroke.isErased);
      }
    });
    _saveStrokes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Sticky Note",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange[800],
          ),
        ),
        // Controls
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Mode Toggle
              ToggleButtons(
                isSelected: [
                  currentMode == DrawingMode.pen,
                  currentMode == DrawingMode.eraser,
                ],
                onPressed: (index) {
                  setState(() {
                    currentMode =
                        index == 0 ? DrawingMode.pen : DrawingMode.eraser;
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.edit),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.cleaning_services),
                  ),
                ],
              ),

              const Spacer(),

              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: strokes.isNotEmpty ? _clearAll : null,
              ),
            ],
          ),
        ),

        // Drawing area
        Expanded(
          child: Container(
            key: _drawingAreaKey,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[300]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: CustomPaint(
                  painter: StickyNotePainter(
                    strokes: strokes,
                    eraserPosition: currentEraserPosition,
                    eraserSize: eraserSize,
                    showEraser: currentMode == DrawingMode.eraser,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StickyNotePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Offset? eraserPosition;
  final double eraserSize;
  final bool showEraser;

  StickyNotePainter({
    required this.strokes,
    this.eraserPosition,
    required this.eraserSize,
    required this.showEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all non-erased strokes
    for (var stroke in strokes) {
      if (!stroke.isErased) {
        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        canvas.drawPath(stroke.path, paint);
      }
    }

    // Draw eraser cursor
    if (showEraser && eraserPosition != null) {
      final eraserPaint = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final eraserBorderPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(eraserPosition!, eraserSize, eraserPaint);
      canvas.drawCircle(eraserPosition!, eraserSize, eraserBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant StickyNotePainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        eraserPosition != oldDelegate.eraserPosition ||
        eraserSize != oldDelegate.eraserSize ||
        showEraser != oldDelegate.showEraser;
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/get_proc_cubit/cubit/get_proc_cubit.dart';
import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import '../../../canvas_screen/presentation/view/canvas_screen.dart';
import '../../../core/failed_msg_screen_widget.dart';
import '../../../core/repos/data_repo_impl.dart';
import '../../../core/utils/api_service.dart';
import '../../../get_files_cubit/cubit/get_files_cubit.dart';
import '../../../patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import '../../data/image_model.dart';
import 'widgets/full_screen_img_view.dart';
import 'package:dio/dio.dart';
import 'dart:ui' as ui;
import 'dart:convert';

class VisitImages extends StatefulWidget {
  const VisitImages({super.key, required this.patientInfo});
  final PatientInfo patientInfo;

  @override
  State<VisitImages> createState() => _VisitImagesState();
}

class _VisitImagesState extends State<VisitImages> {
  List<ImageModel> images = [];

  @override
  initState() {
    super.initState();
    context
        .read<GetFilesCubit>()
        .getImages3("P${widget.patientInfo.patientId}", null, true);
  }

  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return Colors.black;
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      // إذا كان على شكل #RRGGBB
      if (colorValue.startsWith('#')) {
        return Color(int.parse(colorValue.replaceFirst('#', '0xff')));
      }
      // إذا كان على شكل Color(...) -> نستخرج الأرقام
      final regex = RegExp(r'red: ([\d.]+), green: ([\d.]+), blue: ([\d.]+)');
      final match = regex.firstMatch(colorValue);
      if (match != null) {
        final r = double.parse(match.group(1)!) * 255;
        final g = double.parse(match.group(2)!) * 255;
        final b = double.parse(match.group(3)!) * 255;
        return Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt());
      }
    }
    return Colors.black;
  }

  Future<Uint8List?> generateThumbnailFromStrokes(String base64Str,
      {int size = 200}) async {
    try {
      // 1️⃣ فك التشفير من Base64 إلى JSON string
      final jsonStr = utf8.decode(base64Decode(base64Str));

      // 2️⃣ نفك الـ JSON
      final decoded = jsonDecode(jsonStr);

      // 🔹 نتأكد من الشكل (Map أو List)
      List strokesList;
      if (decoded is Map<String, dynamic> && decoded.containsKey('strokes')) {
        strokesList = decoded['strokes'];
      } else if (decoded is List) {
        strokesList = decoded;
      } else {
        throw Exception('Invalid strokes JSON format');
      }

      final strokes = strokesList.map((e) => StrokeModel.fromJson(e)).toList();

      // 3️⃣ نبدأ الرسم
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // خلفية بيضاء
      final paintBg = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), paintBg);

      // ارسم strokes
      for (final stroke in strokes) {
        final paint = Paint()
          ..color = _parseColor(stroke.color)
          ..strokeWidth = stroke.width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final path = Path();
        if (stroke.points.isNotEmpty) {
          path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
          for (var point in stroke.points.skip(1)) {
            path.lineTo(point.dx, point.dy);
          }
          canvas.drawPath(path, paint);
        }
      }

      // 4️⃣ حول الناتج لصورة PNG
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("⚠️ Error generating thumbnail: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientInfo.name.isNotEmpty
            ? widget.patientInfo.name
            : widget.patientInfo.firstName),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<GetFilesCubit, GetFilesState>(
              listener: (context, state) {
                if (state is GetFilesSuccess) {
                  // images = List<ImageModel>.from(state.images)
                  //   ..sort((a, b) => b.imgName.compareTo(a.imgName));
                  images = state.images;
                  // Sort images
                }
              },
              builder: (context, state) {
                if (state is GetFilesSuccess) {
                  if (images.isNotEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<GetFilesCubit>().getImages3(
                            "P${widget.patientInfo.patientId}", null, true);
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.all(15),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    ImageModel currentImage = images[index];

                                    if (currentImage.isDrawing) {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              HandwritingScreen(
                                            imageModel: ImageModel(
                                              imgName: images[index].imgName,
                                              strokesJson:
                                                  images[index].strokesJson,
                                            ),
                                            patientId:
                                                widget.patientInfo.patientId,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        context
                                            .read<GetFilesCubit>()
                                            .getImages3(
                                              "P${widget.patientInfo.patientId}",
                                              null,
                                              false,
                                            );
                                      }
                                    } else {
                                      viewImage(images,
                                          index); // 🔹 بس استدعاء عادي بدون await أو result
                                    }
                                  },
                                  child: images[index].isImage
                                      ? Image.memory(
                                          images[index].imgBase64!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.image_not_supported_rounded,
                                              size: 100,
                                            );
                                          },
                                        )
                                      : FutureBuilder<Uint8List?>(
                                          future: generateThumbnailFromStrokes(
                                              images[index].strokesJson!),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            }
                                            if (snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(
                                                    Icons
                                                        .image_not_supported_rounded,
                                                    size: 100,
                                                  );
                                                },
                                              );
                                            } else {
                                              return const Center(
                                                  child: Icon(Icons.draw));
                                            }
                                          },
                                        ),
                                ),
                                // الاسم فوق الصورة
                                Positioned(
                                  top: 8, // المسافة من فوق
                                  left: 8, // المسافة من الشمال
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    color: Colors.black
                                        .withOpacity(0.5), // خلفية شبه شفافة
                                    child: Text(
                                      images[index].imgName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    debugPrint("");
                    return WarningMsgScreen(
                      onRefresh: () async {
                        context.read<GetFilesCubit>().getImages3(
                            "P${widget.patientInfo.patientId}", null, true);
                      },
                      state: state,
                      msg: "No Visits",
                    );
                  }
                } else if (state is GetFilesFaild) {
                  return WarningMsgScreen(
                    onRefresh: () async {
                      context.read<GetFilesCubit>().getImages3(
                          "P${widget.patientInfo.patientId}", null, true);
                    },
                    state: state,
                    msg: state.error,
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => UploadPatientVisitsCubit(
                  DataRepoImpl(
                    ApiService(
                      Dio(),
                    ),
                  ),
                ),
                child: HandwritingScreen(
                  patientId: widget.patientInfo.patientId,
                ),
              ),
            ),
          );
          if (result == true) {
            context
                .read<GetFilesCubit>()
                .getImages3("P${widget.patientInfo.patientId}", null, false);
          }
        },
        child: const Icon(Icons.create),
      ),
    );
  }

  void viewImage(List<ImageModel> imageList, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<GetProcCubit>(
                create: (context) => GetProcCubit(
                      DataRepoImpl(ApiService(
                        Dio(),
                      )),
                    )),
            BlocProvider<UploadPatientVisitsCubit>(
              create: (context) => UploadPatientVisitsCubit(
                DataRepoImpl(
                  ApiService(
                    Dio(),
                  ),
                ),
              ),
            ),
            BlocProvider<UpdatePatientStateCubit>(
              create: (context) => UpdatePatientStateCubit(
                DataRepoImpl(
                  ApiService(
                    Dio(),
                  ),
                ),
              ),
            ),
          ],
          child: FullscreenImageScreen(
            patientId: widget.patientInfo.patientId,
            allImage: imageList,
            initialIndex: index,
          ),
        ),
      ),
    );
  }
}

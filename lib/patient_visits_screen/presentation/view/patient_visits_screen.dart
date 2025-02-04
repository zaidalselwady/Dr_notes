import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hand_write_notes/canvas_screen/presentation/view/canvas_screen.dart';
import 'package:hand_write_notes/get_files_cubit/cubit/get_files_cubit.dart';
import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import 'package:hand_write_notes/patient_visits_screen/presentation/manger/patient_questionnaire_cubit/cubit/patient_questionnaire_cubit.dart';
import 'package:hand_write_notes/patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
import 'package:hand_write_notes/questionnaire_screen/presentation/view/questionnaire.dart';
import 'package:hand_write_notes/show_info_screen/presentation/view/show_info_screen.dart';
import 'package:intl/intl.dart';
import '../../../core/failed_msg_screen_widget.dart';
import '../../../core/repos/data_repo_impl.dart';
import '../../../core/utils/api_service.dart';
import '../../../get_proc_cubit/cubit/get_proc_cubit.dart';
import '../../../login_screen/data/user_model.dart';
import '../../../show_info_screen/presentation/manger/update_patient_info_cubit/cubit/update_patient_info_cubit.dart';
import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import '../../data/image_model.dart';
import 'widgets/full_screen_img_view.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

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

// Future<File> _cacheImage(Uint8List imageBytes, int index) async {
//   final cacheManager = DefaultCacheManager();
//   final cacheKey = "image_$index"; // Unique key for each image

//   // ✅ Check if image exists in cache
//   final fileInfo = await cacheManager.getFileFromCache(cacheKey);
//   if (fileInfo != null) {
//     return fileInfo.file; // Return cached image
//   }

//   // ✅ Store Uint8List as a file in cache
//   final file = await cacheManager.putFile(cacheKey, imageBytes);
//   return file;
// }

class _PatientVisitsScreenState extends State<PatientVisitsScreen> {
  int calculateAgeInYears(String birthDate) {
    try {
      // Define possible date formats
      final List<String> dateFormats = ['d-M-yyyy', 'dd-MM-yyyy', 'yyyy-MM-dd'];

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
  Widget build(BuildContext context) {
    int age = calculateAgeInYears(widget.patientsInfo.birthDate);

    return BlocProvider(
      create: (context) => GetFilesCubit(
        DataRepoImpl(
          ApiService(Dio()),
        ),
      )..getImages3("P${widget.patientId}"),
      child: Scaffold(
        appBar: AppBar(),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                "assets/background.png",
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Always visible patient info card
              PatientInfoCard(
                patientInfo: widget.patientsInfo,
                medicalHistory: "",
                age: age.toString(),
              ),
              if (widget.user.userName == "Dr")
                Expanded(
                  child: BlocBuilder<GetFilesCubit, GetFilesState>(
                    builder: (context, state) {
                      if (state is GetFilesSuccess) {
                        if (state.images.isNotEmpty) {
                          return RefreshIndicator(
                            onRefresh: () async {
                              context
                                  .read<GetFilesCubit>()
                                  .getImages3("P${widget.patientId}");
                            },
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemCount: state.images.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => viewImage(state.images, index),
                                  child: Image.memory(
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                          Icons.image_not_supported_rounded);
                                    },
                                    state.images[index].imgBase64,
                                    fit: BoxFit.fill,
                                  ),
                                );
                              },
                            ),
                          );
                        } else {
                          return WarningMsgScreen(
                            onRefresh: () async {
                              context
                                  .read<GetFilesCubit>()
                                  .getImages3("P${widget.patientId}");
                            },
                            state: state,
                            msg: "No Visits",
                          );
                        }
                      } else if (state is GetFilesFaild) {
                        return WarningMsgScreen(
                          onRefresh: () async {
                            context
                                .read<GetFilesCubit>()
                                .getImages3("P${widget.patientId}");
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
                )

              // Expanded(
              //   child: BlocBuilder<GetFilesCubit, GetFilesState>(
              //     builder: (context, state) {
              //       if (state is GetFilesSuccess) {
              //         if (state.images.isNotEmpty) {
              //           return RefreshIndicator(
              //             onRefresh: () async {
              //               context
              //                   .read<GetFilesCubit>()
              //                   .getImages("P${widget.patientId}");
              //             },
              //             child: GridView.builder(
              //               gridDelegate:
              //                   const SliverGridDelegateWithFixedCrossAxisCount(
              //                 crossAxisCount: 3,
              //                 crossAxisSpacing: 4,
              //                 mainAxisSpacing: 4,
              //               ),
              //               itemCount: state.images.length,
              //               itemBuilder: (context, index) {
              //                 return GestureDetector(
              //                   onTap: () => viewImage(state.images, index),
              //                   child: Image.memory(
              //                     errorBuilder: (context, error, stackTrace) {
              //                       return const Icon(
              //                           Icons.image_not_supported_rounded);
              //                     },
              //                     state.images[index].imgBase64,
              //                     fit: BoxFit.fill,
              //                   ),
              //                 );
              //               },
              //             ),
              //           );
              //         } else {
              //           return WarningMsgScreen(
              //             onRefresh: () async {
              //               context
              //                   .read<GetFilesCubit>()
              //                   .getImages("P${widget.patientId}");
              //             },
              //             state: state,
              //             msg: "No Visits",
              //           );
              //         }
              //       } else if (state is GetFilesFaild) {
              //         return WarningMsgScreen(
              //           onRefresh: () async {
              //             context
              //                 .read<GetFilesCubit>()
              //                 .getImages("P${widget.patientId}");
              //           },
              //           state: state,
              //           msg: state.error,
              //         );
              //       } else {
              //         return const Center(
              //           child: CircularProgressIndicator(),
              //         );
              //       }
              //     },
              //   ),
              // )
              else
                const Center(
                    child: Text(
                  "No access to this feature",
                  style: TextStyle(fontSize: 20),
                ))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: widget.user.userName == "Dr"
              ? () {
                  Navigator.push(
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
                          patientId: widget.patientId,
                        ),
                      ),
                    ),
                  );
                }
              : null,
          child: const Icon(Icons.create),
        ),
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
            patientId: widget.patientId,
            image: imageList,
            initialIndex: index,
          ),
        ),
      ),
    );
  }
}

class PatientInfoCard extends StatelessWidget {
  final String age;
  final String medicalHistory;
  final PatientInfo patientInfo;
  const PatientInfoCard({
    super.key,
    required this.age,
    required this.medicalHistory,
    required this.patientInfo,
  });

  @override
  Widget build(BuildContext context) {
    var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);

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
                  CircleAvatar(
                    backgroundColor: Colors.teal[800], // Background color
                    radius: 40, // Adjust CircleAvatar size
                    child: ClipOval(
                      child: Image.asset(
                        "assets/tooth.png",
                        fit: BoxFit.contain, // Ensures the image fits well
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
                          style: const TextStyle(
                            fontSize: 20,
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
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Color(0xFFDDA853),
                      size: 30,
                    ),
                    onPressed: () {
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
                      // Handle view history action
                    },
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 1),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {
                      updateCubit.updateClientsWithSoapRequest(
                          "UPDATE Patients_Info SET isOnClinic = 0 WHERE Patient_Id=${patientInfo.patientId}");
                    },
                    child: Text(
                      "Finish visit",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

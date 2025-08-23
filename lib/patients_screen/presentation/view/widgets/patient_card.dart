import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_write_notes/core/repos/data_repo_impl.dart';
import 'package:hand_write_notes/core/utils/api_service.dart';
import 'package:hand_write_notes/delete_patient_cubit/cubit/delete_patient_cubit.dart';
import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import 'package:hand_write_notes/login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';
import 'package:hand_write_notes/patient_visits_screen/presentation/manger/patient_questionnaire_cubit/cubit/patient_questionnaire_cubit.dart';
import 'package:hand_write_notes/patient_visits_screen/presentation/view/patient_visits_screen.dart';
import 'package:hand_write_notes/update_patient_state_cubit/cubit/update_patient_state_cubit.dart';

import '../../../../login_screen/data/user_model.dart';

class PatientCard extends StatefulWidget {
  const PatientCard({
    super.key,
    required this.patientsInfo,
    // required this.onDelete,
    // required this.onCancel,
  });
  final PatientInfo patientsInfo;
  // final VoidCallback onDelete;
  // final Function(PatientInfo) onCancel;

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  User? user;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  void fetchUser() async {
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    user = await saveCubit.getUser();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
    var deleteCubit = BlocProvider.of<DeletePatientCubit>(context);

    bool isInClinic = widget.patientsInfo.isInClinic;
    return Dismissible(
      key: Key('${widget.patientsInfo.patientId}'),
      onDismissed: (direction) async {
        if (user!.userName == "Dr") {
          // widget.onDelete();
          PatientInfo? patientInfo =
              await _showDeleteDialog(context, deleteCubit);
          if (patientInfo != null) {
            // widget.onCancel(patientInfo);
          }
          // showAdaptiveDialog(
          //   context: context,
          //   builder: (context) {
          //     bool isChecked = false;
          //     return StatefulBuilder(
          //       builder: (context, setState) {
          //         return AlertDialog(
          //           title: const Text('Delete Patient'),
          //           content: Column(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Row(
          //                 children: [
          //                   Checkbox(
          //                     value: isChecked,
          //                     onChanged: (value) {
          //                       setState(() {
          //                         isChecked = value ?? false;
          //                       });
          //                     },
          //                   ),
          //                   const Flexible(
          //                     child: Text(
          //                         'Are you sure you want to delete this patient?'),
          //                   ),
          //                 ],
          //               ),
          //             ],
          //           ),
          //           actions: [
          //             TextButton(
          //               onPressed: isChecked
          //                   ? () {
          //                       Navigator.of(context)
          //                           .pop(); // Replace with your delete logic
          //                       deleteCubit.deletePatient(
          //                           "DELETE FROM Patients WHERE Patient_Id = ${widget.patientsInfo[widget.index].patientId};");
          //                     }
          //                   : null, // Disable button if checkbox isn't checked
          //               child: const Text("Delete"),
          //             ),
          //             TextButton(
          //               onPressed: () {
          //                 Navigator.of(context).pop();
          //               },
          //               child: const Text("Cancel"),
          //             ),
          //           ],
          //         );
          //       },
          //     );
          //   },
          // );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
                onTap: () async {
                  int id = widget.patientsInfo.patientId;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => PatientQuestionnaireCubit(
                          DataRepoImpl(
                            ApiService(
                              Dio(),
                            ),
                          ),
                        ),
                        child: PatientVisitsScreen(
                          user: user!,
                          patientsInfo: widget.patientsInfo,
                          patientId: id,
                        ),
                      ),
                    ),
                  );
                },
                child: Card(
                  color: const Color(0xffFFFFFF),
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/patients.png"),
                        opacity: 0.2,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.patientsInfo.firstName} ${widget.patientsInfo.midName} ${widget.patientsInfo.lastName}",
                            style: GoogleFonts.cairo(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.035,
                              color: const Color(0xFF243642),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(
                              height: 5), // Small space between names
                          Text(
                            widget.patientsInfo.name, // Arabic Name
                            style: GoogleFonts.roboto(
                              // Use an Arabic-friendly font 
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.03,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w700
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ),
          BlocBuilder<UpdatePatientStateCubit, UpdatePatientStateState>(
            builder: (context, state) {
              bool isUpdating = state is UpdatingPatientState;
              return ToggleButtonWidget(
                patientsInfo: widget.patientsInfo,
                //index: widget.index,
                isInClinic: isInClinic,
                isUpdating: isUpdating,
                updateCubit: updateCubit,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<PatientInfo?> _showDeleteDialog(
      BuildContext context, DeletePatientCubit deleteCubit) {
    bool isChecked = false;

    return showAdaptiveDialog<PatientInfo>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Patient'),
              content: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (value) {
                      setState(() {
                        isChecked = value ?? false;
                      });
                    },
                  ),
                  const Flexible(
                    child:
                        Text('Are you sure you want to delete this patient?'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isChecked
                      ? () {
                          deleteCubit.deletePatient(
                              "UPDATE Patients_Info SET Status = 1 WHERE Patient_Id = ${widget.patientsInfo.patientId}",
                              widget.patientsInfo.patientId);
                          Navigator.of(context).pop(); // No value returned
                        }
                      : null,
                  child: const Text("Delete"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(widget.patientsInfo);
                  },
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ToggleButtonWidget extends StatefulWidget {
  final bool isInClinic;
  final bool isUpdating;
  final UpdatePatientStateCubit updateCubit;
  final PatientInfo
      patientsInfo; // Adjust the type based on your data structure
  //final int index;

  const ToggleButtonWidget({
    required this.isInClinic,
    required this.isUpdating,
    required this.updateCubit,
    required this.patientsInfo,
    //required this.index,
    super.key,
  });

  @override
  _ToggleButtonWidgetState createState() => _ToggleButtonWidgetState();
}

class _ToggleButtonWidgetState extends State<ToggleButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [widget.patientsInfo.isInClinic], // Use the latest data
      onPressed: widget.isUpdating
          ? null
          : (toggleIndex) {
              // Immediately update the UI by modifying patientsInfo directly
              setState(() {
                widget.patientsInfo.isInClinic =
                    !widget.patientsInfo.isInClinic;
              });

              // Perform the database update
              widget.updateCubit.updatePatient(
                "UPDATE Patients_Info SET isOnClinic = ${widget.patientsInfo.isInClinic ? 1 : 0} WHERE Patient_Id=${widget.patientsInfo.patientId}",
              );
            },
      fillColor: const Color(0xFF009688).withOpacity(0.2),
      color: const Color(0xFF243642),
      borderColor: widget.patientsInfo.isInClinic
          ? const Color(0xFF009688)
          : const Color(0xFF243642),
      selectedColor: const Color(0xFF009688),
      children: const [
        Icon(Icons.check_box),
      ],
    );
  }
}

// class _ToggleButtonWidgetState extends State<ToggleButtonWidget> {
//   late bool localIsInClinic;
//   @override
//   void initState() {
//     super.initState();
//     localIsInClinic = widget.isInClinic; // Initialize local state
//   }
//   @override
//   Widget build(BuildContext context) {
//     return ToggleButtons(
//       isSelected: [widget.patientsInfo.isInClinic],
//       onPressed: widget.isUpdating
//           ? null
//           : (toggleIndex) {
//               setState(() {
//                 // Toggle the local state immediately
//                 localIsInClinic = !localIsInClinic;
//               });
//               // Perform the update
//               widget.updateCubit.updateClientsWithSoapRequest(
//                 "UPDATE Patients_Info SET isOnClinic = ${localIsInClinic ? 1 : 0} WHERE Patient_Id=${widget.patientsInfo.patientId}",
//               );
//             },
//       fillColor: const Color(0xFF009688).withOpacity(0.2),
//       color: const Color(0xFF243642),
//       borderColor:
//           localIsInClinic ? const Color(0xFF009688) : const Color(0xFF243642),
//       selectedColor: const Color(0xFF009688),
//       children: const [
//         Icon(Icons.check_box),
//       ],
//     );
//   }
// }

// BlocConsumer<UpdatePatientStateCubit, UpdatePatientStateState>(
//           listener: (context, state) {
//             // TODO: implement listener
//           },
//           builder: (context, state) {
//             return ToggleButtons(
//               isSelected: [
//                 isInClinic[widget.index]
//               ], // Pass a single boolean as a list
//               onPressed: (index) {
//                 setState(() {
//                   isInClinic[widget.index] = !isInClinic[widget.index];
//                 });
//                 print(isInClinic);
//               },
//               selectedColor: Colors.green,
//               selectedBorderColor: Colors.green,
//               fillColor: Colors.green.withOpacity(0.3),
//               borderColor: Colors.grey,
//               children: const [
//                 Icon(
//                   Icons.check_box,
//                 ),
//               ],
//             );
//           },
//         ),
// BlocBuilder<UpdatePatientStateCubit, UpdatePatientStateState>(
//   builder: (context, state) {
//     // Check if the state is updating to modify appearance
//     bool isUpdating = state is UpdatingPatientState;
//     // Set colors based on state
//     Color borderColor = Colors.grey;
//     Color fillColor = Colors.green.withOpacity(0.3);
//     Color color = Colors.grey;
//     if (state is UpdatePatientStateSuccess) {
//       setState(() {});
//     }
//     if (state is UpdatingPatientState) {
//       return const CircularProgressIndicator();
//     } else if (state is UpdatePatientStateFaild) {
//       // // Highlight failure
//       // borderColor = Colors.red;
//       // fillColor = Colors.red.withOpacity(0.3);
//       // color = Colors.red;
//     }
//     return ToggleButtons(
//       isSelected: [
//         isInClinic[widget.index]
//       ], // Pass a single boolean as a list
//       onPressed: isUpdating
//           ? null // Disable button when updating
//           : (index) {
//               setState(() {
//                 isInClinic[widget.index] = !isInClinic[widget.index];
//               });
//               // Trigger the state update in the Cubit
//               updateCubit.updateClientsWithSoapRequest(
//                 widget.patientsInfo[widget.index].patientId,
//                 isInClinic[widget.index] == true ? 1 : 0,
//               );
//             },
//       color: widget.patientsInfo[widget.index].isInClinic == true
//           ? Colors.green
//           : Colors.amber,
//       fillColor: fillColor,
//       borderColor: borderColor,
//       children: const [
//         Icon(
//           Icons.check_box,
//         ),
//       ],
//     );
//   },
// ),

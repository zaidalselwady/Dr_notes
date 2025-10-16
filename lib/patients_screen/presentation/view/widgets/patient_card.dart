// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hand_write_notes/core/repos/data_repo_impl.dart';
// import 'package:hand_write_notes/core/utils/api_service.dart';
// import 'package:hand_write_notes/delete_patient_cubit/cubit/delete_patient_cubit.dart';
// import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
// import 'package:hand_write_notes/login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';
// import 'package:hand_write_notes/patient_visits_screen/presentation/manger/patient_questionnaire_cubit/cubit/patient_questionnaire_cubit.dart';
// import 'package:hand_write_notes/patient_visits_screen/presentation/view/patient_visits_screen.dart';
// import 'package:hand_write_notes/update_patient_state_cubit/cubit/update_patient_state_cubit.dart';

// import '../../../../login_screen/data/user_model.dart';

// class PatientCard extends StatefulWidget {
//   const PatientCard({
//     super.key,
//     required this.patientsInfo,
//     // required this.onDelete,
//     // required this.onCancel,
//   });
//   final PatientInfo patientsInfo;
//   // final VoidCallback onDelete;
//   // final Function(PatientInfo) onCancel;

//   @override
//   State<PatientCard> createState() => _PatientCardState();
// }

// class _PatientCardState extends State<PatientCard> {
//   User? user;

//   @override
//   void initState() {
//     super.initState();
//     fetchUser();
//   }

//   void fetchUser() async {
//     var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
//     user = await saveCubit.getUser();
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
//     var deleteCubit = BlocProvider.of<DeletePatientCubit>(context);

//     bool isInClinic = widget.patientsInfo.isInClinic;
//     return Dismissible(
//       key: Key('${widget.patientsInfo.patientId}'),
//       onDismissed: (direction) async {
//         if (user!.userName == "Dr") {
//           // widget.onDelete();
//           PatientInfo? patientInfo =
//               await _showDeleteDialog(context, deleteCubit);
//           if (patientInfo != null) {
//             // widget.onCancel(patientInfo);
//           }
//           // showAdaptiveDialog(
//           //   context: context,
//           //   builder: (context) {
//           //     bool isChecked = false;
//           //     return StatefulBuilder(
//           //       builder: (context, setState) {
//           //         return AlertDialog(
//           //           title: const Text('Delete Patient'),
//           //           content: Column(
//           //             mainAxisSize: MainAxisSize.min,
//           //             children: [
//           //               Row(
//           //                 children: [
//           //                   Checkbox(
//           //                     value: isChecked,
//           //                     onChanged: (value) {
//           //                       setState(() {
//           //                         isChecked = value ?? false;
//           //                       });
//           //                     },
//           //                   ),
//           //                   const Flexible(
//           //                     child: Text(
//           //                         'Are you sure you want to delete this patient?'),
//           //                   ),
//           //                 ],
//           //               ),
//           //             ],
//           //           ),
//           //           actions: [
//           //             TextButton(
//           //               onPressed: isChecked
//           //                   ? () {
//           //                       Navigator.of(context)
//           //                           .pop(); // Replace with your delete logic
//           //                       deleteCubit.deletePatient(
//           //                           "DELETE FROM Patients WHERE Patient_Id = ${widget.patientsInfo[widget.index].patientId};");
//           //                     }
//           //                   : null, // Disable button if checkbox isn't checked
//           //               child: const Text("Delete"),
//           //             ),
//           //             TextButton(
//           //               onPressed: () {
//           //                 Navigator.of(context).pop();
//           //               },
//           //               child: const Text("Cancel"),
//           //             ),
//           //           ],
//           //         );
//           //       },
//           //     );
//           //   },
//           // );
//         }
//       },
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: InkWell(
//                 onTap: () async {
//                   int id = widget.patientsInfo.patientId;
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => BlocProvider(
//                         create: (context) => PatientQuestionnaireCubit(
//                           DataRepoImpl(
//                             ApiService(
//                               Dio(),
//                             ),
//                           ),
//                         ),
//                         child: PatientVisitsScreen(
//                           user: user!,
//                           patientsInfo: widget.patientsInfo,
//                           patientId: id,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//                 child: Card(
//                   color: const Color(0xffFFFFFF),
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       image: DecorationImage(
//                         image: AssetImage("assets/patients.png"),
//                         opacity: 0.2,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                     child: Padding(
//                       padding:  EdgeInsets.all(MediaQuery.of(context).size.width * 0.01,),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "${widget.patientsInfo.firstName} ${widget.patientsInfo.midName} ${widget.patientsInfo.lastName}",
//                             style: GoogleFonts.cairo(
//                               fontSize:
//                                   MediaQuery.of(context).size.width * 0.025,
//                               color: const Color(0xFF243642),
//                             ),
//                             textDirection: TextDirection.rtl,
//                           ),
//                           const SizedBox(
//                               height: 5), // Small space between names
//                           Text(
//                             widget.patientsInfo.name, // Arabic Name
//                             style: GoogleFonts.roboto(
//                                 // Use an Arabic-friendly font
//                                 fontSize:
//                                     MediaQuery.of(context).size.width * 0.03,
//                                 color: Colors.grey[800],
//                                 fontWeight: FontWeight.w700),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 )),
//           ),
//           BlocBuilder<UpdatePatientStateCubit, UpdatePatientStateState>(
//             builder: (context, state) {
//               bool isUpdating = state is UpdatingPatientState;
//               return ToggleButtonWidget(
//                 patientsInfo: widget.patientsInfo,
//                 //index: widget.index,
//                 isInClinic: isInClinic,
//                 isUpdating: isUpdating,
//                 updateCubit: updateCubit,
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Future<PatientInfo?> _showDeleteDialog(
//       BuildContext context, DeletePatientCubit deleteCubit) {
//     bool isChecked = false;

//     return showAdaptiveDialog<PatientInfo>(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: const Text('Delete Patient'),
//               content: Row(
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
//                     child:
//                         Text('Are you sure you want to delete this patient?'),
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: isChecked
//                       ? () {
//                           deleteCubit.deletePatient(
//                               "UPDATE Patients_Info SET Status = 1 WHERE Patient_Id = ${widget.patientsInfo.patientId}",
//                               widget.patientsInfo.patientId);
//                           Navigator.of(context).pop(); // No value returned
//                         }
//                       : null,
//                   child: const Text("Delete"),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop(widget.patientsInfo);
//                   },
//                   child: const Text("Cancel"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }

// class ToggleButtonWidget extends StatefulWidget {
//   final bool isInClinic;
//   final bool isUpdating;
//   final UpdatePatientStateCubit updateCubit;
//   final PatientInfo
//       patientsInfo; // Adjust the type based on your data structure
//   //final int index;

//   const ToggleButtonWidget({
//     required this.isInClinic,
//     required this.isUpdating,
//     required this.updateCubit,
//     required this.patientsInfo,
//     //required this.index,
//     super.key,
//   });

//   @override
//   _ToggleButtonWidgetState createState() => _ToggleButtonWidgetState();
// }

// class _ToggleButtonWidgetState extends State<ToggleButtonWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return ToggleButtons(
//       isSelected: [widget.patientsInfo.isInClinic], // Use the latest data
//       onPressed: widget.isUpdating
//           ? null
//           : (toggleIndex) {
//               // Immediately update the UI by modifying patientsInfo directly
//               setState(() {
//                 widget.patientsInfo.isInClinic =
//                     !widget.patientsInfo.isInClinic;
//               });

//               // Perform the database update
//               widget.updateCubit.updatePatient(
//                   "UPDATE Patients_Info SET isOnClinic = ${widget.patientsInfo.isInClinic ? 1 : 0} WHERE Patient_Id=${widget.patientsInfo.patientId}",
//                   true);
//             },
//       fillColor: const Color(0xFF009688).withOpacity(0.2),
//       color: const Color(0xFF243642),
//       borderColor: widget.patientsInfo.isInClinic
//           ? const Color(0xFF009688)
//           : const Color(0xFF243642),
//       selectedColor: const Color(0xFF009688),
//       children: const [
//         Icon(Icons.check_box),
//       ],
//     );
//   }
// }

// // class _ToggleButtonWidgetState extends State<ToggleButtonWidget> {
// //   late bool localIsInClinic;
// //   @override
// //   void initState() {
// //     super.initState();
// //     localIsInClinic = widget.isInClinic; // Initialize local state
// //   }
// //   @override
// //   Widget build(BuildContext context) {
// //     return ToggleButtons(
// //       isSelected: [widget.patientsInfo.isInClinic],
// //       onPressed: widget.isUpdating
// //           ? null
// //           : (toggleIndex) {
// //               setState(() {
// //                 // Toggle the local state immediately
// //                 localIsInClinic = !localIsInClinic;
// //               });
// //               // Perform the update
// //               widget.updateCubit.updateClientsWithSoapRequest(
// //                 "UPDATE Patients_Info SET isOnClinic = ${localIsInClinic ? 1 : 0} WHERE Patient_Id=${widget.patientsInfo.patientId}",
// //               );
// //             },
// //       fillColor: const Color(0xFF009688).withOpacity(0.2),
// //       color: const Color(0xFF243642),
// //       borderColor:
// //           localIsInClinic ? const Color(0xFF009688) : const Color(0xFF243642),
// //       selectedColor: const Color(0xFF009688),
// //       children: const [
// //         Icon(Icons.check_box),
// //       ],
// //     );
// //   }
// // }

// // BlocConsumer<UpdatePatientStateCubit, UpdatePatientStateState>(
// //           listener: (context, state) {
// //             // TODO: implement listener
// //           },
// //           builder: (context, state) {
// //             return ToggleButtons(
// //               isSelected: [
// //                 isInClinic[widget.index]
// //               ], // Pass a single boolean as a list
// //               onPressed: (index) {
// //                 setState(() {
// //                   isInClinic[widget.index] = !isInClinic[widget.index];
// //                 });
// //                 print(isInClinic);
// //               },
// //               selectedColor: Colors.green,
// //               selectedBorderColor: Colors.green,
// //               fillColor: Colors.green.withOpacity(0.3),
// //               borderColor: Colors.grey,
// //               children: const [
// //                 Icon(
// //                   Icons.check_box,
// //                 ),
// //               ],
// //             );
// //           },
// //         ),
// // BlocBuilder<UpdatePatientStateCubit, UpdatePatientStateState>(
// //   builder: (context, state) {
// //     // Check if the state is updating to modify appearance
// //     bool isUpdating = state is UpdatingPatientState;
// //     // Set colors based on state
// //     Color borderColor = Colors.grey;
// //     Color fillColor = Colors.green.withOpacity(0.3);
// //     Color color = Colors.grey;
// //     if (state is UpdatePatientStateSuccess) {
// //       setState(() {});
// //     }
// //     if (state is UpdatingPatientState) {
// //       return const CircularProgressIndicator();
// //     } else if (state is UpdatePatientStateFaild) {
// //       // // Highlight failure
// //       // borderColor = Colors.red;
// //       // fillColor = Colors.red.withOpacity(0.3);
// //       // color = Colors.red;
// //     }
// //     return ToggleButtons(
// //       isSelected: [
// //         isInClinic[widget.index]
// //       ], // Pass a single boolean as a list
// //       onPressed: isUpdating
// //           ? null // Disable button when updating
// //           : (index) {
// //               setState(() {
// //                 isInClinic[widget.index] = !isInClinic[widget.index];
// //               });
// //               // Trigger the state update in the Cubit
// //               updateCubit.updateClientsWithSoapRequest(
// //                 widget.patientsInfo[widget.index].patientId,
// //                 isInClinic[widget.index] == true ? 1 : 0,
// //               );
// //             },
// //       color: widget.patientsInfo[widget.index].isInClinic == true
// //           ? Colors.green
// //           : Colors.amber,
// //       fillColor: fillColor,
// //       borderColor: borderColor,
// //       children: const [
// //         Icon(
// //           Icons.check_box,
// //         ),
// //       ],
// //     );
// //   },
// // ),

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hand_write_notes/core/repos/data_repo_impl.dart';
// import 'package:hand_write_notes/core/utils/api_service.dart';
// import 'package:hand_write_notes/delete_patient_cubit/cubit/delete_patient_cubit.dart';
// import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
// import 'package:hand_write_notes/login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';
// import 'package:hand_write_notes/patient_visits_screen/presentation/manger/patient_questionnaire_cubit/cubit/patient_questionnaire_cubit.dart';
// import 'package:hand_write_notes/patient_visits_screen/presentation/view/patient_visits_screen.dart';
// import 'package:hand_write_notes/update_patient_state_cubit/cubit/update_patient_state_cubit.dart';

// import '../../../../login_screen/data/user_model.dart';

// class PatientCard extends StatefulWidget {
//   const PatientCard({
//     super.key,
//     required this.patientsInfo,
//   });
//   final PatientInfo patientsInfo;

//   @override
//   State<PatientCard> createState() => _PatientCardState();
// }

// class _PatientCardState extends State<PatientCard>
//     with TickerProviderStateMixin {
//   User? user;
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   late AnimationController _statusAnimationController;
//   late Animation<Color?> _statusColorAnimation;

//   @override
//   void initState() {
//     super.initState();
//     fetchUser();
//     _setupAnimations();
//   }

//   void _setupAnimations() {
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 150),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.95,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));

//     _statusAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _statusColorAnimation = ColorTween(
//       begin: Colors.grey.shade300,
//       end: const Color(0xFF4CAF50),
//     ).animate(CurvedAnimation(
//       parent: _statusAnimationController,
//       curve: Curves.easeInOut,
//     ));

//     if (widget.patientsInfo.isInClinic) {
//       _statusAnimationController.forward();
//     }
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _statusAnimationController.dispose();
//     super.dispose();
//   }

//   void fetchUser() async {
//     var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
//     user = await saveCubit.getUser();
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
//     var deleteCubit = BlocProvider.of<DeletePatientCubit>(context);
//     final screenWidth = MediaQuery.of(context).size.width;

//     return AnimatedBuilder(
//       animation: _scaleAnimation,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _scaleAnimation.value,
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
//             child: Dismissible(
//               key: Key('${widget.patientsInfo.patientId}'),
//               background: _buildDismissBackground(true),
//               secondaryBackground: _buildDismissBackground(false),
//               onDismissed: (direction) async {
//                 if (user?.userName == "Dr") {
//                   PatientInfo? patientInfo =
//                       await _showDeleteDialog(context, deleteCubit);
//                   if (patientInfo != null) {
//                     // Handle cancel action
//                   }
//                 }
//               },
//               child: _buildMainCard(context, updateCubit, screenWidth),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDismissBackground(bool isLeft) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.red.shade50,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.red.shade200, width: 1),
//       ),
//       child: Align(
//         alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.delete_outline,
//                 color: Colors.red.shade600,
//                 size: 28,
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Delete',
//                 style: TextStyle(
//                   color: Colors.red.shade600,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMainCard(BuildContext context, UpdatePatientStateCubit updateCubit, double screenWidth) {
//     return GestureDetector(
//       onTapDown: (_) => _animationController.forward(),
//       onTapUp: (_) => _animationController.reverse(),
//       onTapCancel: () => _animationController.reverse(),
//       onTap: () => _navigateToPatientVisits(context),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.white,
//               Colors.grey.shade50,
//             ],
//           ),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.shade200,
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//               spreadRadius: 1,
//             ),
//           ],
//           border: Border.all(
//             color: Colors.grey.shade200,
//             width: 1,
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(16),
//           child: Stack(
//             children: [
//               _buildBackgroundPattern(),
//               _buildCardContent(context, updateCubit, screenWidth),
//               _buildStatusIndicator(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBackgroundPattern() {
//     return Positioned.fill(
//       child: Opacity(
//         opacity: 0.05,
//         child: Container(
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage("assets/patients.png"),
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCardContent(BuildContext context, UpdatePatientStateCubit updateCubit, double screenWidth) {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Row(
//         children: [
//           _buildPatientAvatar(),
//           const SizedBox(width: 16),
//           Expanded(
//             child: _buildPatientInfo(screenWidth),
//           ),
//           const SizedBox(width: 16),
//           _buildStatusToggle(updateCubit),
//         ],
//       ),
//     );
//   }

//   Widget _buildPatientAvatar() {
//     return Container(
//       width: 56,
//       height: 56,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             const Color(0xFF4CAF50).withOpacity(0.8),
//             const Color(0xFF2E7D32),
//           ],
//         ),
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF4CAF50).withOpacity(0.3),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: const Icon(
//         Icons.person,
//         color: Colors.white,
//         size: 28,
//       ),
//     );
//   }

//   Widget _buildPatientInfo(double screenWidth) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "${widget.patientsInfo.firstName} ${widget.patientsInfo.midName} ${widget.patientsInfo.lastName}",
//           style: GoogleFonts.cairo(
//             fontSize: screenWidth * 0.032,
//             fontWeight: FontWeight.w700,
//             color: const Color(0xFF1A1A1A),
//             height: 1.2,
//           ),
//           textDirection: TextDirection.rtl,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           widget.patientsInfo.name,
//           style: GoogleFonts.roboto(
//             fontSize: screenWidth * 0.028,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey.shade600,
//             height: 1.2,
//           ),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 8),
//         _buildPatientStatus(),
//       ],
//     );
//   }

//   Widget _buildPatientStatus() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: widget.patientsInfo.isInClinic
//             ? const Color(0xFF4CAF50).withOpacity(0.1)
//             : Colors.orange.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: widget.patientsInfo.isInClinic
//               ? const Color(0xFF4CAF50).withOpacity(0.3)
//               : Colors.orange.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             widget.patientsInfo.isInClinic
//                 ? Icons.local_hospital
//                 : Icons.schedule,
//             size: 14,
//             color: widget.patientsInfo.isInClinic
//                 ? const Color(0xFF4CAF50)
//                 : Colors.orange,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             widget.patientsInfo.isInClinic ? 'In Clinic' : 'Waiting',
//             style: GoogleFonts.roboto(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: widget.patientsInfo.isInClinic
//                   ? const Color(0xFF4CAF50)
//                   : Colors.orange.shade700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusToggle(UpdatePatientStateCubit updateCubit) {
//     return BlocBuilder<UpdatePatientStateCubit, UpdatePatientStateState>(
//       builder: (context, state) {
//         bool isUpdating = state is UpdatingPatientState;

//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           child: isUpdating
//               ? _buildLoadingIndicator()
//               : _buildToggleSwitch(updateCubit),
//         );
//       },
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return Container(
//       width: 48,
//       height: 48,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         shape: BoxShape.circle,
//       ),
//       child: const Center(
//         child: SizedBox(
//           width: 20,
//           height: 20,
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             color: Color(0xFF4CAF50),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildToggleSwitch(UpdatePatientStateCubit updateCubit) {
//     return GestureDetector(
//       onTap: () => _togglePatientStatus(updateCubit),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 48,
//         height: 48,
//         decoration: BoxDecoration(
//           gradient: widget.patientsInfo.isInClinic
//               ? LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     const Color(0xFF4CAF50),
//                     const Color(0xFF2E7D32),
//                   ],
//                 )
//               : LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Colors.grey.shade300,
//                     Colors.grey.shade400,
//                   ],
//                 ),
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: widget.patientsInfo.isInClinic
//                   ? const Color(0xFF4CAF50).withOpacity(0.3)
//                   : Colors.grey.withOpacity(0.2),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Icon(
//           widget.patientsInfo.isInClinic
//               ? Icons.check_circle
//               : Icons.radio_button_unchecked,
//           color: Colors.white,
//           size: 24,
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusIndicator() {
//     return Positioned(
//       top: 12,
//       right: 12,
//       child: AnimatedBuilder(
//         animation: _statusColorAnimation,
//         builder: (context, child) {
//           return Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: widget.patientsInfo.isInClinic
//                   ? const Color(0xFF4CAF50)
//                   : Colors.orange,
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: widget.patientsInfo.isInClinic
//                       ? const Color(0xFF4CAF50).withOpacity(0.4)
//                       : Colors.orange.withOpacity(0.4),
//                   blurRadius: 4,
//                   spreadRadius: 1,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _togglePatientStatus(UpdatePatientStateCubit updateCubit) {
//     setState(() {
//       widget.patientsInfo.isInClinic = !widget.patientsInfo.isInClinic;
//     });

//     if (widget.patientsInfo.isInClinic) {
//       _statusAnimationController.forward();
//     } else {
//       _statusAnimationController.reverse();
//     }

//     updateCubit.updatePatient(
//       "UPDATE Patients_Info SET isOnClinic = ${widget.patientsInfo.isInClinic ? 1 : 0} WHERE Patient_Id=${widget.patientsInfo.patientId}",
//       true,
//     );
//   }

//   void _navigateToPatientVisits(BuildContext context) async {
//     int id = widget.patientsInfo.patientId;
//     Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
//           create: (context) => PatientQuestionnaireCubit(
//             DataRepoImpl(
//               ApiService(Dio()),
//             ),
//           ),
//           child: PatientVisitsScreen(
//             user: user!,
//             patientsInfo: widget.patientsInfo,
//             patientId: id,
//           ),
//         ),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           const begin = Offset(1.0, 0.0);
//           const end = Offset.zero;
//           const curve = Curves.easeInOut;

//           var tween = Tween(begin: begin, end: end).chain(
//             CurveTween(curve: curve),
//           );

//           return SlideTransition(
//             position: animation.drive(tween),
//             child: child,
//           );
//         },
//         transitionDuration: const Duration(milliseconds: 300),
//       ),
//     );
//   }

//   Future<PatientInfo?> _showDeleteDialog(
//       BuildContext context, DeletePatientCubit deleteCubit) {
//     bool isChecked = false;

//     return showDialog<PatientInfo>(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               title: Row(
//                 children: [
//                   Icon(
//                     Icons.warning_amber_rounded,
//                     color: Colors.orange.shade600,
//                     size: 28,
//                   ),
//                   const SizedBox(width: 12),
//                   const Text(
//                     'Delete Patient',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 20,
//                     ),
//                   ),
//                 ],
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Are you sure you want to delete this patient? This action cannot be undone.',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: isChecked,
//                         onChanged: (value) {
//                           setState(() {
//                             isChecked = value ?? false;
//                           });
//                         },
//                         activeColor: const Color(0xFF4CAF50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                       ),
//                       const Expanded(
//                         child: Text(
//                           'I understand this action is permanent',
//                           style: TextStyle(fontSize: 14),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop(widget.patientsInfo);
//                   },
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.grey.shade600,
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   ),
//                   child: const Text(
//                     'Cancel',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: isChecked
//                       ? () {
//                           deleteCubit.deletePatient(
//                             "UPDATE Patients_Info SET Status = 1 WHERE Patient_Id = ${widget.patientsInfo.patientId}",
//                             widget.patientsInfo.patientId,
//                           );
//                           Navigator.of(context).pop();
//                         }
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red.shade600,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'Delete',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }

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
import 'package:hand_write_notes/patients_screen/presentation/manger/get_patients_cubit/cubit/get_patients_cubit.dart';
import 'package:hand_write_notes/update_patient_state_cubit/cubit/update_patient_state_cubit.dart';

import '../../../../login_screen/data/user_model.dart';

class PatientCard extends StatefulWidget {
  const PatientCard({
    super.key,
    required this.patientsInfo,
    required this.isInClinic,
  });
  final PatientInfo patientsInfo;
  final bool isInClinic;

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard>
    with SingleTickerProviderStateMixin {
  User? user;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    fetchUser();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Dismissible(
              key: Key('${widget.patientsInfo.patientId}'),
              background: _buildSwipeBackground(true),
              secondaryBackground: _buildSwipeBackground(false),
              onDismissed: (direction) async {
                if (user!.userName == "Dr") {
                  PatientInfo? patientInfo =
                      await _showDeleteDialog(context, deleteCubit);
                  if (patientInfo != null) {
                    // Handle cancellation if needed
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) => _animationController.forward(),
                      onTapUp: (_) => _animationController.reverse(),
                      onTapCancel: () => _animationController.reverse(),
                      onTap: () async {
                        await _animationController.reverse();
                        int id = widget.patientsInfo.patientId;
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    BlocProvider(
                              create: (context) => PatientQuestionnaireCubit(
                                DataRepoImpl(ApiService(Dio())),
                              ),
                              child: PatientVisitsScreen(
                                user: user!,
                                patientsInfo: widget.patientsInfo,
                                patientId: id,
                              ),
                            ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                )),
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.grey.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                            ),
                            border: Border.all(
                              color: isInClinic
                                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                                  : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Background pattern
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image:
                                            AssetImage("assets/patients.png"),
                                        opacity: 0.05,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Status indicator dot
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isInClinic
                                        ? const Color(0xFF4CAF50)
                                        : Colors.orange.shade600,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isInClinic
                                            ? const Color(0xFF4CAF50)
                                                .withOpacity(0.4)
                                            : Colors.orange.withOpacity(0.4),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Main content
                              Padding(
                                padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width * 0.015),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isInClinic
                                              ? [
                                                  const Color(0xFF4CAF50),
                                                  const Color(0xFF2E7D32)
                                                ]
                                              : [
                                                  Colors.grey.shade400,
                                                  Colors.grey.shade600
                                                ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: isInClinic
                                                ? const Color(0xFF4CAF50)
                                                    .withOpacity(0.3)
                                                : Colors.grey.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Patient info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${widget.patientsInfo.firstName} ${widget.patientsInfo.midName} ${widget.patientsInfo.lastName}",
                                            style: GoogleFonts.cairo(
                                              color: const Color(0xFF1A1A1A),
                                              fontWeight: FontWeight.w700,
                                              height: 2.4,
                                            ),
                                            textDirection: TextDirection.rtl,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.01),
                                          Text(
                                            widget.patientsInfo.name,
                                            style: GoogleFonts.roboto(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.02),
                                          // Status badge
                                          // Container(
                                          //   padding: const EdgeInsets.symmetric(
                                          //       horizontal: 8, vertical: 4),
                                          //   decoration: BoxDecoration(
                                          //     color: isInClinic
                                          //         ? const Color(0xFF4CAF50)
                                          //             .withOpacity(0.1)
                                          //         : Colors.orange
                                          //             .withOpacity(0.1),
                                          //     borderRadius:
                                          //         BorderRadius.circular(12),
                                          //     border: Border.all(
                                          //       color: isInClinic
                                          //           ? const Color(0xFF4CAF50)
                                          //               .withOpacity(0.3)
                                          //           : Colors.orange
                                          //               .withOpacity(0.3),
                                          //     ),
                                          //   ),
                                          //   child: Row(
                                          //     mainAxisSize: MainAxisSize.min,
                                          //     children: [
                                          //       Icon(
                                          //         isInClinic
                                          //             ? Icons.local_hospital
                                          //             : Icons.schedule,
                                          //         size: 12,
                                          //         color: isInClinic
                                          //             ? const Color(0xFF4CAF50)
                                          //             : Colors.orange.shade700,
                                          //       ),
                                          //       const SizedBox(width: 4),
                                          //       Text(
                                          //         isInClinic
                                          //             ? 'In Clinic'
                                          //             : 'Waiting',
                                          //         style: GoogleFonts.roboto(
                                          //           fontSize: 11,
                                          //           fontWeight: FontWeight.w600,
                                          //           color: isInClinic
                                          //               ? const Color(
                                          //                   0xFF4CAF50)
                                          //               : Colors
                                          //                   .orange.shade700,
                                          //         ),
                                          //       ),
                                          //     ],
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BlocConsumer<UpdatePatientStateCubit,
                      UpdatePatientStateState>(
                    listener: (context, state) async {
                      if (state is UpdatePatientStateSuccess &&
                          widget.isInClinic) {
                        await context
                            .read<GetPatientsCubit>()
                            .fetchPatientsWithSoapRequest(
                                "SELECT * FROM Patients_Info Where isOnClinic = 1 AND Status = 0");
                      }
                    },
                    builder: (context, state) {
                      bool isUpdating = state is UpdatingPatientState;
                      return ToggleButtonWidget(
                        patientsInfo: widget.patientsInfo,
                        isInClinic: isInClinic,
                        isUpdating: isUpdating,
                        updateCubit: updateCubit,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeBackground(bool isLeft) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.red.shade400,
            Colors.red.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<PatientInfo?> _showDeleteDialog(
      BuildContext context, DeletePatientCubit deleteCubit) {
    bool isChecked = false;

    return showDialog<PatientInfo>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade600,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delete Patient',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Are you sure you want to delete this patient?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (value) {
                          setState(() {
                            isChecked = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Flexible(
                        child: Text(
                          'I confirm this action',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(widget.patientsInfo);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: isChecked
                      ? () {
                          deleteCubit.deletePatient(
                            "UPDATE Patients_Info SET Status = 1 WHERE Patient_Id = ${widget.patientsInfo.patientId}",
                            widget.patientsInfo.patientId,
                          );
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
  final PatientInfo patientsInfo;

  const ToggleButtonWidget({
    required this.isInClinic,
    required this.isUpdating,
    required this.updateCubit,
    required this.patientsInfo,
    super.key,
  });

  @override
  _ToggleButtonWidgetState createState() => _ToggleButtonWidgetState();
}

class _ToggleButtonWidgetState extends State<ToggleButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _toggleAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _toggleAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _toggleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isUpdating) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _toggleAnimationController.forward(),
            onTapUp: (_) => _toggleAnimationController.reverse(),
            onTapCancel: () => _toggleAnimationController.reverse(),
            onTap: () async {
              await _toggleAnimationController.reverse();

              setState(() {
                widget.patientsInfo.isInClinic =
                    !widget.patientsInfo.isInClinic;
              });

              widget.updateCubit.updatePatient(
                "UPDATE Patients_Info SET isOnClinic = ${widget.patientsInfo.isInClinic ? 1 : 0} WHERE Patient_Id=${widget.patientsInfo.patientId}",
                true,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: widget.patientsInfo.isInClinic
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xFF2E7D32),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade300,
                          Colors.grey.shade500,
                        ],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.patientsInfo.isInClinic
                        ? const Color(0xFF4CAF50).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: widget.patientsInfo.isInClinic
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Icon(
                widget.patientsInfo.isInClinic
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}

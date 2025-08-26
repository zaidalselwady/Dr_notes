import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hand_write_notes/delete_patient_cubit/cubit/delete_patient_cubit.dart';
import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import '../../manger/get_patients_cubit/cubit/get_patients_cubit.dart';
import 'patient_card.dart';

class CustomPatientsList extends StatefulWidget {
  const CustomPatientsList({
    super.key,
    required this.isAll,
    required this.onLengthChanged,
    required this.onClosestClientCalculated,
    required this.patients,
  });

  final bool isAll;
  final Function(int, int) onLengthChanged;
  final Function(int) onClosestClientCalculated;
  final List<PatientInfo> patients;

  @override
  State<CustomPatientsList> createState() => _CustomPatientsListState();
}

class _CustomPatientsListState extends State<CustomPatientsList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var getPatientsCubit = BlocProvider.of<GetPatientsCubit>(context);
    final width = MediaQuery.of(context).size.width;
    return Column(children: [
      Expanded(
        child: RefreshIndicator(
            onRefresh: () async {
              getPatientsCubit.fetchPatientsWithSoapRequest(widget.isAll
                  ? "SELECT * FROM Patients_Info WHERE Status = 0"
                  : "SELECT * FROM Patients_Info Where isOnClinic = 1 AND Status = 0");
            },
            child: AnimationLimiter(
              child: BlocListener<DeletePatientCubit, DeletePatientState>(
                  listener: (context, state) {
                    if (state is DeletePatientSuccess) {
                      widget.patients.removeWhere(
                          (patient) => patient.patientId == state.patientId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Patient deleted successfully ✅",
                          ),
                        ),
                      );
                      // setState(() {
                      //   widget.patients.add(returnedPatient);
                      //   widget.patients.sort((a, b) => a.patientId
                      //       .compareTo(b.patientId)); // Maintain order
                      // });
                    }
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(width / 30),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    cacheExtent: 250,
                    itemCount: widget.patients.length,
                    itemBuilder: (BuildContext context, int index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        delay: const Duration(milliseconds: 100),
                        child: SlideAnimation(
                          duration: const Duration(milliseconds: 2500),
                          curve: Curves.fastLinearToSlowEaseIn,
                          horizontalOffset: 30,
                          verticalOffset: 300.0,
                          child: FlipAnimation(
                            duration: const Duration(milliseconds: 3000),
                            curve: Curves.fastLinearToSlowEaseIn,
                            flipAxis: FlipAxis.y,
                            child: PatientCard(
                              patientsInfo: widget.patients[index],
                            ),
                          ),
                        ),
                      );
                    },
                  )),
            )),
      ),
    ]);
  }
}

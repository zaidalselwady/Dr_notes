import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/canvas_screen/presentation/view/widgets/proc_dialog.dart';
import 'package:hand_write_notes/canvas_screen/presentation/view/widgets/show_proc_dialog_result.dart';
import '../../../../core/repos/data_repo_impl.dart';
import '../../../../core/utils/api_service.dart';
import '../../../../get_proc_cubit/cubit/get_proc_cubit.dart';
import '../../../../patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
import '../../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import '../../../data/image_model.dart';

class FullscreenImageScreen extends StatefulWidget {
  final List<ImageModel> image;
  final int initialIndex;
  final int patientId;

  const FullscreenImageScreen({
    super.key,
    this.initialIndex = 0,
    required this.image,
    required this.patientId,
  });

  @override
  State<FullscreenImageScreen> createState() => _FullscreenImageScreenState();
}

class _FullscreenImageScreenState extends State<FullscreenImageScreen> {
  late PageController _pageController;
  late String _currentImageName;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentImageName = widget.image[widget.initialIndex].imgName;
  }

  @override
  Widget build(BuildContext context) {
    List tempProcList = [];
    var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
    var uploadVisitsCubit = BlocProvider.of<UploadPatientVisitsCubit>(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(_currentImageName.split(" ").first),
          actions: [
            IconButton(
                onPressed: () async {
                  String imgName = _currentImageName.split(".").first;
                  List<dynamic>? updatedProcedures =
                      await showDialog<List<dynamic>>(
                    context: context,
                    builder: (BuildContext context) {
                      return MultiBlocProvider(
                        providers: [
                          BlocProvider<GetProcCubit>(
                            create: (context) => GetProcCubit(
                              DataRepoImpl(ApiService(
                                Dio(),
                              )),
                            )..fetchPatientsWithSoapRequest(
                                "SELECT pp.Procedure_id AS Procedure_id,pv.Procedure_id AS Proc_id_pv,    pv.id,pp.Procedure_Desc,mp.Main_Procedure_id,mp.Main_Procedure_Desc,    pv.Patient_Id,pv.Visit_Date,pv.Procedure_Status,pv.Notes FROM Patients_Procedures pp LEFT JOIN Patients_Visits pv ON pp.Procedure_id = pv.Procedure_id AND pv.Patient_Id = ${widget.patientId} AND pv.Visit_Date='$imgName' LEFT JOIN Patients_Main_Procedures mp ON pp.Main_Procedure_id = mp.Main_Procedure_id ORDER BY pp.Procedure_id;"),
                          ),
                        ],
                        child: const ProcedureSelectionScreen(),
                      ); // Your dialog
                    },
                  );
                  if (updatedProcedures == null) return;
                  for (var element in updatedProcedures) {
                    if (element['id'] != 0 && element['id'] != null) {
                      updateCubit.updatePatient(
                          "UPDATE Patients_Visits SET Procedure_Status = ${element['percentage']},Notes='${element['notes']}' WHERE id=${element['id']}",
                          updatedProcedures.indexOf(element) ==
                              updatedProcedures.length - 1);
                    } else {
                      tempProcList.clear();
                      tempProcList.add(element);
                      uploadVisitsCubit.uploadPatientVisits(widget.patientId,
                          tempProcList, imgName, element['notes']);
                    }
                  }
                },
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.black,
                ))
          ],
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<UploadPatientVisitsCubit, UploadPatientVisitsState>(
              listener: (context, state) {
                if (state is UploadPatientVisitsSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text('Uploading Successful'),
                    ),
                  );
                } else if (state is UploadPatientVisitsFailed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text('uploading Failed'),
                    ),
                  );
                }
              },
            ),
            BlocListener<UpdatePatientStateCubit, UpdatePatientStateState>(
              listener: (context, state) {
                if (state is UpdatePatientStateSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text('Updating Successful'),
                    ),
                  );
                } else if (state is UpdatePatientStateFaild) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text('Updating Failed'),
                    ),
                  );
                }
              },
            ),
          ],
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.image.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageName = widget.image[index].imgName;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: Image.memory(widget.image[index].imgBase64),
              );
            },
          ),
        ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

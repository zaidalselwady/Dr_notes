import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        title: Text(_currentImageName),
        actions: [
          IconButton(
              onPressed: () async {
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
                              "SELECT pp.Procedure_id AS Procedure_id,pv.Procedure_id AS Proc_id_pv,pv.id,pp.Procedure_Desc,pv.Patient_Id,pv.Visit_Date,pv.Procedure_Status,pv.Notes FROM Patients_Procedures pp LEFT JOIN Patients_Visits pv ON pp.Procedure_id = pv.Procedure_id AND pv.Patient_Id = ${widget.patientId} AND pv.Visit_Date = '$_currentImageName' ORDER BY pp.Procedure_id;"),
                        ),
                      ],
                      child: ProceduresDialog(
                        patientId: widget.patientId,
                        visitDate: _currentImageName,
                      ),
                    ); // Your dialog
                  },
                );
                if (updatedProcedures != null) {
                  for (var element in updatedProcedures) {
                    if (element['id'] != 0 && element['id'] != null) {
                      updateCubit.updateClientsWithSoapRequest(
                          "UPDATE Patients_Visits SET Procedure_Status = ${element['percentage']},Notes='${element['notes']}' WHERE id=${element['id']}");
                    } else {
                      tempProcList.clear();
                      tempProcList.add(element);
                      uploadVisitsCubit.uploadPatientVisits(
                          widget.patientId,
                          tempProcList,
                          widget.image[widget.initialIndex].imgName,
                          element['notes']);
                    }
                  }
                }
              },
              icon: const Icon(
                Icons.info,
                color: Colors.white,
              ))
        ],
      ),
      body: BlocListener<UpdatePatientStateCubit, UpdatePatientStateState>(
        listener: (context, state) {
          if (state is UpdatePatientStateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Updating Successful'),
              ),
            );
          } else if (state is UpdatePatientStateFaild) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Updating Failed'),
              ),
            );
          }
        },
        child: BlocConsumer<UploadPatientVisitsCubit, UploadPatientVisitsState>(
          listener: (context, state) {
            if (state is UploadPatientVisitsSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Uploading Successful'),
                ),
              );
            } else if (state is UploadPatientVisitsFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('uploading Failed'),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is UpdatingPatientState ||
                state is UploadingPatientVisits) {
              return Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return PageView.builder(
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
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}


// SELECT pv.Procedure_id,pp.Procedures_desc,pv.Procedure_Status,pv.Notes FROM Patients_Visits pv INNER JOIN Patients_Procedures pp ON pv.Procedure_id = pp.Procedure_id WHERE pv.Visit_Date = '$_currentImageName' AND pv.Patient_Id =${widget.patientId} 


// SELECT pp.Procedure_id,pp.Procedure_Desc,pv.Patient_Id,pv.Procedure_id,pv.Procedure_Status,pv.Notes,pv.Visit_Date FROM Patients_Procedures pp FULL OUTER JOIN Patients_Visits pv ON pp.Procedure_id = pv.Procedure_id WHERE pv.Visit_Date = '$_currentImageName' AND pv.Patient_Id =${widget.patientId};


//SELECT pp.Procedure_id,pp.Procedure_Desc,pv.Patient_Id,pv.Procedure_id,    pv.Procedure_Status,pv.Notes,pv.Visit_Date FROM Patients_Procedures pp LEFT JOIN    Patients_Visits pv ON pp.Procedure_id = pv.Procedure_id WHERE pv.Patient_Id =${widget.patientId} OR pv.Patient_Id IS NULL UNION pv.Procedure_id AS Procedure_id,NULL AS Procedure_Desc,pv.Patient_Id,    pv.Procedure_id,pv.Procedure_Status,pv.Notes,pv.Visit_Date FROM Patients_Visits pv WHERE pv.Patient_Id =${widget.patientId} AND NOT EXISTS (SELECT 1 FROM Patients_Procedures pp WHERE pp.Procedure_id = pv.Procedure_id);



//SELECT pp.Procedure_id AS Procedure_id,pp.Procedure_Desc,pv.Patient_Id,    pv.Procedure_id AS Visit_Procedure_Id,pv.Procedure_Status,pv.Notes,    pv.Visit_Date FROM Patients_Procedures pp LEFT JOIN Patients_Visits pv ON    pp.Procedure_id = pv.Procedure_id WHERE (pv.Patient_Id = ${widget.patientId} AND pv.Visit_Date = '$_currentImageName') OR pv.Patient_Id IS NULL UNION SELECT     pv.Procedure_id AS Procedure_id,NULL AS Procedure_Desc,pv.Patient_Id,    pv.Procedure_id AS Visit_Procedure_Id,pv.Procedure_Status,pv.Notes,    pv.Visit_Date FROM Patients_Visits pv WHERE pv.Patient_Id = ${widget.patientId}     AND pv.Visit_Date = '$_currentImageName' AND NOT EXISTS (SELECT 1 FROM Patients_Procedures pp WHERE pp.Procedure_id = pv.Procedure_id);


// SELECT pp.Procedure_id AS Procedure_id,pp.Procedure_Desc,pv.Patient_Id,pv.Visit_Date,    pv.Procedure_Status,pv.Notes FROM Patients_Procedures pp LEFT JOIN Patients_Visits pv ON     pp.Procedure_id = pv.Procedure_id AND pv.Patient_Id = ${widget.patientId} AND pv.Visit_Date = '$_currentImageName' ORDER BY pp.Procedure_id;

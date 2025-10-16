import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:hand_write_notes/core/date_format_service.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';
import '../../settings.dart';

part 'upload_patient_visits_state.dart';

class UploadPatientVisitsCubit extends Cubit<UploadPatientVisitsState> {
  UploadPatientVisitsCubit(this.dataRepo) : super(UploadPatientVisitsInitial());
  final DataRepo dataRepo;

  // SettingsService _settings = SettingsService();
  // String dateFormat = "dd/MM/yyyy"; // Default format
  Future<void> uploadPatientVisits(
    int patientId,
    List<dynamic> procedures,
    String imageName,
    String notes,
  ) async {
    emit(UploadingPatientVisits());
    var response;

    // لو فاضي خليها عنصر واحد بديل
    final procs = procedures.isEmpty
        ? [
            {'procedureId': 0, 'percentage': 0, 'notes': null}
          ]
        : procedures;

    for (var element in procs) {
      final procId = element['procedureId'] ?? 0;
      final procStatus = element['percentage'] ?? 0;
      final procNotes =
          element['notes'] == null ? "NULL" : "'${element['notes']}'";
      // final visitDate = imageName.split(".").first;
      const visitDate =
          "CONVERT(VARCHAR(10), DATEADD(HOUR, 3, GETUTCDATE()), 105) + ' ' + CONVERT(VARCHAR(8), DATEADD(HOUR, 3, GETUTCDATE()), 108)";

      response = await dataRepo.fetchWithSoapRequest(
        "Insert_Update_cmd",
        "INSERT INTO Patients_Visits (Patient_Id,Procedure_id,Visit_Date,Procedure_Status,Notes) "
            "VALUES ($patientId , $procId , $visitDate , $procStatus , N$procNotes)",
      );
    }

    response.fold((failure) {
      emit(UploadPatientVisitsFailed(error: failure.errorMsg));
    }, (inserted) async {
      final document = xml.XmlDocument.parse(inserted.body);
      final resultElement =
          document.findAllElements('Insert_Update_cmdResult').first;
      final jsonString = resultElement.innerText;
      if (jsonString == "1") {
        emit(UploadPatientVisitsSuccess());
      } else {
        emit(UploadPatientVisitsFailed(error: "Failed"));
      }
    });
  }

  // Future<void> uploadPatientVisits(int patientId, List<dynamic> procedures,
  //     String visitDate, String notes) async {
  //   emit(UploadingPatientVisits());
  //   var response;

  //   for (var element in procedures) {
  //     response = await dataRepo.fetchWithSoapRequest("Insert_Update_cmd",
  //         "INSERT INTO Patients_Visits (Patient_Id,Procedure_id,Visit_Date,Procedure_Status,Notes) VALUES ($patientId , ${element['procedureId']} , '$visitDate' , ${element['percentage']},'${element['notes']}')");
  //     if (procedures.indexOf(element) == procedures.length - 1) {}
  //   }
  //   response.fold((failure) {
  //     emit(UploadPatientVisitsFailed(error: failure.errorMsg));
  //   }, (inserted) async {
  //     final document = xml.XmlDocument.parse(inserted.body);
  //     final resultElement =
  //         document.findAllElements('Insert_Update_cmdResult').first;
  //     final jsonString = resultElement.innerText;
  //     if (jsonString == "1") {
  //       emit(
  //         UploadPatientVisitsSuccess(),
  //       );
  //     } else {
  //       emit(
  //         UploadPatientVisitsFailed(error: "Failed"),
  //       );
  //     }
  //   });
  // }
}

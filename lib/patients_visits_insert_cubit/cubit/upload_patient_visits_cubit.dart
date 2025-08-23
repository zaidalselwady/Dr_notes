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
  Future<void> uploadPatientVisits(int patientId, List<dynamic> procedureId,
      String visitDate, String notes) async {
    emit(UploadingPatientVisits());
    // dateFormat = _settings.getString(AppSettingsKeys.dateFormat,
    //     defaultValue: "dd/MM/yyyy");
    var response;
    // String visitDate1 = visitDate.split(' ')[0];
    //String date = DateService.format(visitDate, dateFormat);
    for (var element in procedureId) {
      response = await dataRepo.fetchWithSoapRequest("Insert_Update_cmd",
          "INSERT INTO Patients_Visits (Patient_Id,Procedure_id,Visit_Date,Procedure_Status,Notes) VALUES ($patientId , ${element['procedureId']} , '$visitDate' , ${element['percentage']},'${element['notes']}')");
      if (procedureId.indexOf(element) == procedureId.length - 1) {}
    }
    response.fold((failure) {
      emit(UploadPatientVisitsFailed(error: failure.errorMsg));
    }, (inserted) async {
      final document = xml.XmlDocument.parse(inserted.body);
      final resultElement =
          document.findAllElements('Insert_Update_cmdResult').first;
      final jsonString = resultElement.innerText;
      if (jsonString == "1") {
        emit(
          UploadPatientVisitsSuccess(),
        );
      } else {
        emit(
          UploadPatientVisitsFailed(error: "Failed"),
        );
      }
    });
  }
}

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';

part 'upload_patient_visits_state.dart';

class UploadPatientVisitsCubit extends Cubit<UploadPatientVisitsState> {
  UploadPatientVisitsCubit(this.dataRepo) : super(UploadPatientVisitsInitial());
  final DataRepo dataRepo;
  Future<void> uploadPatientVisits(int patientId, List<dynamic> procedureId,
      String visitDate, String notes) async {
    emit(UploadingPatientVisits());
    var response;
    String visitDate1 = visitDate.split(' ')[0];
    for (var element in procedureId) {
      response = await dataRepo.fetchWithSoapRequest("Insert_Update_cmd",
          "INSERT INTO Patients_Visits (Patient_Id,Procedure_id,Visit_Date,Procedure_Status,Notes) VALUES ($patientId , ${element['procedureId']} , '$visitDate1' , ${element['percentage']},'${element['notes']}')");
      emit(UploadingPatientVisits());
    }

    response.fold((failure) {
      emit(UploadPatientVisitsFailed(error: failure.errorMsg));
    }, (inserted) async {
      final document = xml.XmlDocument.parse(inserted.body);
      final resultElement =
          document.findAllElements('Insert_Update_cmdResult').first;
      final jsonString = resultElement.innerText;
      emit(
        UploadPatientVisitsSuccess(),
      );
    });
  }
}

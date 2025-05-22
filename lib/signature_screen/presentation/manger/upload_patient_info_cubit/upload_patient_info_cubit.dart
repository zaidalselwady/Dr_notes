import 'package:bloc/bloc.dart';
import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import 'package:meta/meta.dart';
import '../../../../core/repos/data_repo.dart';
import 'package:xml/xml.dart' as xml;
part 'upload_patient_info_state.dart';

class UploadPatientInfoCubit extends Cubit<UploadPatientInfoState> {
  UploadPatientInfoCubit(this.dataRepo) : super(UploadPatientInfoInitial());
  final DataRepo dataRepo;
  Future<void> uploadPatientInfo(PatientInfo childInfo) async {
    emit(UploadingPatientInfo());
    var response = await dataRepo.fetchWithSoapRequest("SProc_cmd",
        "exec dbo.SProc_Patients_Info '${childInfo.name}' ,N'${childInfo.firstName}' ,N'${childInfo.midName}' ,N'${childInfo.lastName}' , '${childInfo.birthDate}' , '${childInfo.address}' , '${childInfo.phone}' , '${childInfo.email}' , '${childInfo.school}' , '${childInfo.motherName}'");

    response.fold((failure) {
      emit(UploadPatientInfoFaild(error: failure.errorMsg));
    }, (inserted) async {
      final document = xml.XmlDocument.parse(inserted.body);
      final resultElement = document.findAllElements('SProc_cmdResult').first;
      final jsonString = resultElement.innerText;
      emit(
        UploadPatientInfoSuccess(
          patientId: int.parse(jsonString), //PATIENT ID
        ),
      );
    });
  }
}

// var response = await dataRepo.fetchWithSoapRequest("Insert_Update_cmd",
//         "INSERT INTO Patients_Info (name,birthDate,address,phone,email,school,motherName)Values(${childInfo.name},${childInfo.birthDate},${childInfo.address},${childInfo.phone},${childInfo.email},${childInfo.school},${childInfo.motherName})");

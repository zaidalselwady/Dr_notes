import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../../../../core/repos/data_repo.dart';

part 'update_patient_info_state.dart';

class UpdatePatientInfoCubit extends Cubit<UpdatePatientInfoState> {
  UpdatePatientInfoCubit(this.dataRepo) : super(UpdatePatientInfoInitial());
  final DataRepo dataRepo;

  Future<void> updateClientsWithSoapRequest(
      int patientId,
      String address,
      String email,
      String phone,
      String school,
      String name,
      String firstName,
      String midName,
      String lastName) async {
    emit(UpdatingPatientInfo());
    var result = await dataRepo.fetchWithSoapRequest("Insert_Update_cmd",
        "UPDATE Patients_Info SET address=N'$address' , email='$email' , phone='$phone' , school=N'$school' , name='$name' , FirstName=N'$firstName' , MiddleName=N'$midName' , LastName=N'$lastName' WHERE Patient_Id=$patientId");
    result.fold((failure) {
      emit(
        UpdatePatientInfoFailed(error: failure.errorMsg),
      );
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);
      final resultElement =
          document.findAllElements('Insert_Update_cmdResult').first;
      final jsonString = resultElement.innerText;
      if (int.parse(jsonString) == 1) {
        emit(UpdatePatientInfoSuccess());
      } else {
        UpdatePatientInfoFailed(error: "error");
      }
    });
  }
}

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';
part 'delete_patient_state.dart';

class DeletePatientCubit extends Cubit<DeletePatientState> {
  DeletePatientCubit(this.dataRepo) : super(DeletePatientInitial());
  final DataRepo dataRepo;
  Future<void> deletePatient(String sqlStr,int patientId) async {
    emit(DeletingPatient());
    var result =
        await dataRepo.fetchWithSoapRequest("Insert_Update_cmd", sqlStr);
    result.fold((failure) {
      emit(
        DeletePatientFailed(error: failure.errorMsg),
      );
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);
      final resultElement =
          document.findAllElements('Insert_Update_cmdResult').first;
      final jsonString = resultElement.innerText;
      if (int.parse(jsonString) == 1) {
        emit(DeletePatientSuccess(
          patientId: patientId
        ));
      } else {}
    });
  }
}

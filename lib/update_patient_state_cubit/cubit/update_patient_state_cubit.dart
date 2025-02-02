import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';

part 'update_patient_state_state.dart';

class UpdatePatientStateCubit extends Cubit<UpdatePatientStateState> {
  UpdatePatientStateCubit(this.dataRepo) : super(UpdatePatientStateInitial());
  final DataRepo dataRepo;
  Future<void> updateClientsWithSoapRequest(String sqlStr) async {
    emit(UpdatingPatientState());
    var result =
        await dataRepo.fetchWithSoapRequest("Insert_Update_cmd", sqlStr);
    result.fold((failure) {
      emit(
        UpdatePatientStateFaild(error: failure.errorMsg),
      );
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);
      final resultElement =
          document.findAllElements('Insert_Update_cmdResult').first;
      final jsonString = resultElement.innerText;
      if (int.parse(jsonString) == 1) {
        emit(UpdatePatientStateSuccess(
        ));
      } else {}
    });
  }
}

// UPDATE Patients_Visits SET Procedure_Status = 4,Notes='Done' WHERE id=26'
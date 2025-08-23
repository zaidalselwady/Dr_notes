import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';
import '../../questionnaire_screen/data/questionnaire_model.dart';

part 'update_patient_state_state.dart';

class UpdatePatientStateCubit extends Cubit<UpdatePatientStateState> {
  UpdatePatientStateCubit(this.dataRepo) : super(UpdatePatientStateInitial());
  final DataRepo dataRepo;
  Future<void> updatePatientQuestionnaire(
      List<QuestionnaireModel> questionnaireAnswers, int patientId) async {
    emit(UpdatingPatientState());

    List<String> updateFields = [];

    // Build update fields for both answers and notes
    for (int i = 0; i < questionnaireAnswers.length; i++) {
      final questionNum = i + 1;
      final question = questionnaireAnswers[i];

      // Add answer update
      final answerValue = question.answer == null
          ? "NULL"
          : question.answer!
              ? "1"
              : "0";
      updateFields.add('Q$questionNum = $answerValue');

      // Add note update
      String noteValue;
      if (question.answer == true &&
          question.note != null &&
          question.note!.isNotEmpty) {
        // Escape single quotes and wrap in quotes
        final escapedNote = question.note!.replaceAll("'", "''");
        noteValue = "'$escapedNote'";
      } else {
        noteValue = "NULL";
      }
      updateFields.add('Q${questionNum}_Note = $noteValue');
    }

    final String updateQuery = """
    UPDATE Patients_Questionnaire 
    SET ${updateFields.join(', ')} 
    WHERE Patient_Id = $patientId
  """;

    var result =
        await dataRepo.fetchWithSoapRequest("Insert_Update_cmd", updateQuery);

    result.fold((failure) {
      emit(UpdatePatientStateFaild(error: failure.errorMsg));
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);
      final resultElement =
          document.findAllElements('Insert_Update_cmdResult').first;
      final jsonString = resultElement.innerText;

      if (int.parse(jsonString) == 1) {
        emit(UpdatePatientStateSuccess());
      } else {
        emit(UpdatePatientStateFaild(error: "Update failed"));
      }
    });
  }

// 4. HELPER FUNCTION - Builds update query string (for use in your existing updatePatient method)
  String buildQuestionnaireUpdateQuery(
      List<QuestionnaireModel> questionnaireAnswers, int patientId) {
    List<String> updateFields = [];

    for (int i = 0; i < questionnaireAnswers.length; i++) {
      final questionNum = i + 1;
      final question = questionnaireAnswers[i];

      // Add answer update
      final answerValue = question.answer == null
          ? "NULL"
          : question.answer!
              ? "1"
              : "0";
      updateFields.add('Q$questionNum = $answerValue');

      // Add note update
      String noteValue;
      if (question.answer == true &&
          question.note != null &&
          question.note!.isNotEmpty) {
        final escapedNote = question.note!.replaceAll("'", "''");
        noteValue = "'$escapedNote'";
      } else {
        noteValue = "NULL";
      }
      updateFields.add('Q${questionNum}_Note = $noteValue');
    }

    return "UPDATE Patients_Questionnaire SET ${updateFields.join(', ')} WHERE Patient_Id = $patientId";
  }

  Future<void> updatePatient(String sqlStr) async {
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
        emit(UpdatePatientStateSuccess());
      } else {}
    });
  }
}

// UPDATE Patients_Visits SET Procedure_Status = 4,Notes='Done' WHERE id=26'



  